package com.eatzy.eatzy_vendor

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.json.JSONArray
import org.json.JSONObject

/**
 * MainActivity with MethodChannel AND EventChannel support.
 *
 * - MethodChannel: Starts native voice service from Flutter.
 * - EventChannel: Streams voice results (ACCEPT, REJECT, etc.) from native service to Flutter.
 */
class MainActivity : FlutterActivity() {
    private val METHOD_CHANNEL = "com.eatzy.eatzy_vendor/native"
    private val EVENT_CHANNEL = "com.eatzy/vendor_voice_events"
    private val PENDING_EVENT_CHANNEL = "com.eatzy/pending_action_events"
    
    private var methodChannel: MethodChannel? = null
    private var eventsSink: EventChannel.EventSink? = null
    private var pendingSink: EventChannel.EventSink? = null

    private val voiceResultReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val type = intent?.getStringExtra("type") ?: return
            val payloadStr = intent.getStringExtra("payload") ?: "{}"

            try {
                // Parse payload string into JSONObject for proper nesting
                val payloadObj = JSONObject(payloadStr)
                
                val map = JSONObject()
                map.put("type", type)
                map.put("payload", payloadObj)

                // Send as JSON string - Flutter will decode
                eventsSink?.success(map.toString())
            } catch (e: Exception) {
                // Fallback: send as-is if parsing fails
                val map = JSONObject()
                map.put("type", type)
                map.put("payload", payloadStr)
                eventsSink?.success(map.toString())
            }
        }
    }

    private val pendingActionReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val event = intent?.getStringExtra("event") ?: return
            val payloadStr = intent?.getStringExtra("payload") ?: "{}"
            
            try {
                val map = JSONObject()
                map.put("event", event)
                map.put("payload", JSONObject(payloadStr))
                pendingSink?.success(map.toString())
            } catch (e: Exception) {
                val map = JSONObject()
                map.put("event", event)
                map.put("payload", payloadStr)
                pendingSink?.success(map.toString())
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. Setup MethodChannel (to start service from Flutter)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startNativeVoiceService" -> {
                    val orderJson = call.argument<String>("orderJson") ?: "{}"
                    EatzyForegroundService.startServiceWithOrder(this, orderJson)
                    result.success(true)
                }
                "isEnterpriseEnabled" -> {
                    result.success(false)
                }
                "getPendingActions" -> {
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            val dao = com.eatzy.eatzy_vendor.db.AppDatabase.getInstance(applicationContext).pendingActionDao()
                            val list = dao.getAll()
                            val out = JSONArray()
                            for (pa in list) {
                                val obj = JSONObject()
                                obj.put("uuid", pa.uuid)
                                obj.put("action", pa.action)
                                obj.put("orderId", pa.orderId)
                                obj.put("payloadJson", pa.payloadJson)
                                obj.put("attempts", pa.attempts)
                                obj.put("nextTryAt", pa.nextTryAt)
                                out.put(obj)
                            }
                            runOnUiThread {
                                result.success(out.toString())
                            }
                        } catch (e: Exception) {
                            runOnUiThread {
                                result.error("DB_ERROR", e.message, null)
                            }
                        }
                    }
                }
                "sendPendingAction" -> {
                    val map = call.argument<Map<String, Any>>("action") ?: emptyMap()
                    val uuid = map["uuid"] as? String ?: java.util.UUID.randomUUID().toString()
                    val action = (map["action"] as? String) ?: "unknown"
                    val orderId = (map["orderId"] as? String) ?: ""
                    val payloadJson = (map["payloadJson"] as? String) ?: "{}"

                    // write into Room and schedule WorkManager
                    CoroutineScope(Dispatchers.IO).launch {
                       val pa = com.eatzy.eatzy_vendor.db.PendingAction(
                           uuid = uuid, 
                           action = action, 
                           orderId = orderId, 
                           payloadJson = payloadJson, 
                           attempts = 0, 
                           nextTryAt = System.currentTimeMillis()
                       )
                       val db = com.eatzy.eatzy_vendor.db.AppDatabase.getInstance(applicationContext)
                       db.pendingActionDao().upsert(pa)
                       
                       val work = androidx.work.OneTimeWorkRequestBuilder<com.eatzy.eatzy_vendor.sync.PendingActionWorker>().build()
                       androidx.work.WorkManager.getInstance(applicationContext).enqueue(work)
                       
                       runOnUiThread { result.success(true) }
                    }
                }
                else -> result.notImplemented()
            }
        }

        // 2. Setup EventChannel (to stream results to Flutter)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(args: Any?, sink: EventChannel.EventSink?) {
                    eventsSink = sink
                }

                override fun onCancel(args: Any?) {
                    eventsSink = null
                }
            })

        // 3. Setup Pending Action EventChannel
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, PENDING_EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(args: Any?, sink: EventChannel.EventSink?) {
                    pendingSink = sink
                }

                override fun onCancel(args: Any?) {
                    pendingSink = null
                }
            })

        // 4. Register BroadcastReceivers
        val filterVoice = IntentFilter("com.eatzy.eatzy_vendor.VOICE_RESULT")
        val filterPending = IntentFilter("com.eatzy.eatzy_vendor.PENDING_ACTION_EVENT")
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(voiceResultReceiver, filterVoice, Context.RECEIVER_NOT_EXPORTED)
            registerReceiver(pendingActionReceiver, filterPending, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(voiceResultReceiver, filterVoice)
            registerReceiver(pendingActionReceiver, filterPending)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            unregisterReceiver(voiceResultReceiver)
            unregisterReceiver(pendingActionReceiver)
        } catch (e: Exception) { }
    }
}
