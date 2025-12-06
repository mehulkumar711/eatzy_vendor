package com.eatzy.eatzy_vendor

import android.app.*
import android.content.Context
import android.content.Intent
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioRecord
import android.media.MediaPlayer
import android.media.MediaRecorder
import android.os.*
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.speech.tts.TextToSpeech
import android.util.Log
import androidx.core.app.NotificationCompat
import kotlinx.coroutines.*
import org.json.JSONObject
import java.util.*
import kotlin.math.log10

private const val TAG = "EatzyFGService"
private const val CHANNEL_ID = "eatzy_voice_channel"
private const val NOTIF_ID = 1987
private const val ACTION_START = "ACTION_START_VOICE_FLOW"
private const val EXTRA_ORDER = "EXTRA_ORDER_JSON"

/**
 * EatzyForegroundService (S2 - Advanced Smart Service)
 *
 * Event-triggered foreground service that handles voice order processing when app is backgrounded.
 * Features:
 * - Tasty Ping playback
 * - TTS order readout
 * - STT for vendor response
 * - Noise detection with semi-voice fallback
 * - WakeLock management
 * - Result broadcast to Flutter via MethodChannel
 */
class EatzyForegroundService : Service(), TextToSpeech.OnInitListener {

    private val serviceScope = CoroutineScope(Dispatchers.Default + Job())
    private var tts: TextToSpeech? = null
    private var speechRecognizer: SpeechRecognizer? = null
    private var audioRecorder: AudioRecord? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var mediaPlayer: MediaPlayer? = null

    // S2/S3 Dependencies
    private lateinit var pendingRepo: com.eatzy.eatzy_vendor.sync.PendingActionRepository
    private lateinit var apiService: com.eatzy.eatzy_vendor.net.ApiService

    // Config
    private val listenTimeoutMs = 12_000L // 12 seconds
    private val repeatOnceIfNoResponse = true
    private val noiseThresholdDb = 65.0 // above this -> noise fallback
    private val audioBufferSize = AudioRecord.getMinBufferSize(
        16000,
        AudioFormat.CHANNEL_IN_MONO,
        AudioFormat.ENCODING_PCM_16BIT
    )

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        tts = TextToSpeech(this, this)
        
        // Initialize Native Sync (S2/S3)
        // Initialize Native Sync (S2/S3)
        // Note: Using a placeholder URL for now. In production, use BuildConfig.EATZY_API_BASE_URL
        apiService = com.eatzy.eatzy_vendor.net.ApiService.create("http://10.0.2.2:3000/") 
        val db = com.eatzy.eatzy_vendor.db.AppDatabase.getInstance(this)
        pendingRepo = com.eatzy.eatzy_vendor.sync.PendingActionRepository(this, apiService, db.pendingActionDao())
        // Polling is replaced by WorkManager in Repository
    }

    /**
     * Queue a pending action to Room DB for reliable retry.
     * Use this when network fails or app is backgrounded/killed.
     */
    private fun queuePendingAction(action: String, orderId: String, payloadMap: Map<String, Any?>) {
        val uuid = UUID.randomUUID().toString()
        val pa = com.eatzy.eatzy_vendor.db.PendingAction(
            uuid = uuid,
            action = action,
            orderId = orderId,
            payloadJson = JSONObject(payloadMap).toString(),
            attempts = 0,
            nextTryAt = System.currentTimeMillis()
        )
        // Save to Room via Repository
        serviceScope.launch(Dispatchers.IO) {
            pendingRepo.addOrUpdate(pa)
            Log.d(TAG, "Queued pending action: $action for order $orderId")
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        serviceScope.launch {
            try {
                val orderJson = intent?.getStringExtra(EXTRA_ORDER) ?: "{}"
                handleOrder(JSONObject(orderJson))
            } catch (e: Exception) {
                Log.e(TAG, "start command error", e)
                stopSelf()
            }
        }
        return START_NOT_STICKY
    }

    private suspend fun handleOrder(order: JSONObject) {
        withContext(Dispatchers.Main) {
            startForeground(NOTIF_ID, buildNotification("Processing order..."))
            acquireWakeLock()
        }

        try {
            // 1. Play Tasty Ping (local raw resource)
            playPing()

            // 2. Prepare TTS text (map order JSON -> spoken sentence)
            val spoken = formatOrderForTTS(order)
            speakTTS(spoken, locale = mapLocale(order.optString("locale", "en_US")))

            // 3. Wait for TTS to finish, then start noise meter
            delay(600)
            val noisy = isNoisyEnvironment()

            if (noisy) {
                // fallback: don't start STT; rely on semi-voice / manual UI
                sendResultToFlutter("AWAIT_MANUAL", mapOf("orderId" to order.optString("id")))
            } else {
                // 4. Run STT for 1st attempt
                val recognized = runSpeechRecognition(listenTimeoutMs)
                if (recognized.isNullOrBlank() && repeatOnceIfNoResponse) {
                    // repeat TTS once
                    speakTTS(spoken, locale = mapLocale(order.optString("locale", "en_US")))
                    val recognized2 = runSpeechRecognition(listenTimeoutMs)
                    processSpeechResult(recognized2, order)
                } else {
                    processSpeechResult(recognized, order)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "error handling order", e)
            sendResultToFlutter("ERROR", mapOf("message" to (e.message ?: "Unknown error")))
        } finally {
            releaseWakeLock()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                stopForeground(STOP_FOREGROUND_REMOVE)
            } else {
                @Suppress("DEPRECATION")
                stopForeground(true)
            }
            stopSelf()
        }
    }

    private fun formatOrderForTTS(order: JSONObject): String {
        val id = order.optString("id", "unknown")
        val isParcel = order.optBoolean("isParcel", true)
        val itemsArr = order.optJSONArray("items")
        val items = mutableListOf<String>()
        if (itemsArr != null) {
            for (i in 0 until itemsArr.length()) {
                val it = itemsArr.optJSONObject(i)
                if (it != null) {
                    val qty = it.optInt("quantity", 1)
                    val name = it.optString("name", "item")
                    items.add("$qty $name")
                }
            }
        }
        val itemsText = items.joinToString(", ")
        return "Order Number $id. ${if (isParcel) "Parcel" else "Dine in"}. Items: $itemsText. Accept? Reject? Ready?"
    }

    private fun mapLocale(locale: String): Locale {
        return when {
            locale.startsWith("hi") -> Locale("hi", "IN")
            locale.startsWith("gu") -> Locale("gu", "IN")
            else -> Locale("en", "US")
        }
    }

    private fun playPing() {
        try {
            val resId = resources.getIdentifier("tasty_ping", "raw", packageName)
            if (resId != 0) {
                mediaPlayer = MediaPlayer.create(this, resId)
                @Suppress("DEPRECATION")
                mediaPlayer?.setAudioStreamType(AudioManager.STREAM_MUSIC)
                mediaPlayer?.start()
                // Wait for ping to complete
                while (mediaPlayer?.isPlaying == true) {
                    Thread.sleep(100)
                }
            }
        } catch (e: Exception) {
            Log.w(TAG, "playPing failed", e)
        }
    }

    private fun speakTTS(text: String, locale: Locale = Locale("en", "US")) {
        tts?.language = locale
        tts?.speak(text, TextToSpeech.QUEUE_FLUSH, null, "ORDER_TTS")
        // Wait until done
        var timeout = 0
        while (tts?.isSpeaking == true && timeout < 10000) {
            Thread.sleep(100)
            timeout += 100
        }
    }

    private fun runSpeechRecognition(timeoutMs: Long): String? {
        var recognizedText: String? = null
        val latch = java.util.concurrent.CountDownLatch(1)
        try {
            if (SpeechRecognizer.isRecognitionAvailable(this)) {
                Handler(Looper.getMainLooper()).post {
                    speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this)
                    val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                        putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                        putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, false)
                        putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
                    }
                    speechRecognizer?.setRecognitionListener(object : RecognitionListener {
                        override fun onReadyForSpeech(params: Bundle?) {}
                        override fun onBeginningOfSpeech() {}
                        override fun onRmsChanged(rmsdB: Float) {}
                        override fun onBufferReceived(buffer: ByteArray?) {}
                        override fun onEndOfSpeech() {}
                        override fun onError(error: Int) {
                            Log.w(TAG, "Speech error $error")
                            latch.countDown()
                        }
                        override fun onResults(results: Bundle?) {
                            val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                            if (!matches.isNullOrEmpty()) recognizedText = matches[0]
                            latch.countDown()
                        }
                        override fun onPartialResults(partialResults: Bundle?) {}
                        override fun onEvent(eventType: Int, params: Bundle?) {}
                    })
                    speechRecognizer?.startListening(intent)
                }
                latch.await(timeoutMs + 1000, java.util.concurrent.TimeUnit.MILLISECONDS)
                Handler(Looper.getMainLooper()).post {
                    try {
                        speechRecognizer?.stopListening()
                        speechRecognizer?.destroy()
                    } catch (e: Exception) { }
                }
            } else {
                Log.w(TAG, "SpeechRecognizer not available")
            }
        } catch (e: Exception) {
            Log.e(TAG, "runSpeechRecognition error", e)
        }
        return recognizedText
    }

    private fun processSpeechResult(recognized: String?, order: JSONObject) {
        if (recognized.isNullOrBlank()) {
            sendResultToFlutter("AWAIT_MANUAL", mapOf("orderId" to order.optString("id")))
            return
        }
        val normalized = recognized.lowercase(Locale.ROOT)
        when {
            normalized.contains("accept") || normalized.contains("ok") || normalized.contains("ठीक") || normalized.contains("સ્વી") || normalized.contains("haan") || normalized.contains("theek") -> {
                sendResultToFlutter("ACCEPT", mapOf("orderId" to order.optString("id"), "recognized" to recognized))
            }
            normalized.contains("reject") || normalized.contains("cancel") || normalized.contains("रद्द") || normalized.contains("રદ") || normalized.contains("nahi") -> {
                sendResultToFlutter("REJECT", mapOf("orderId" to order.optString("id"), "recognized" to recognized))
            }
            normalized.contains("ready") || normalized.contains("tayyar") || normalized.contains("તૈયાર") || normalized.contains("तैयार") -> {
                sendResultToFlutter("READY", mapOf("orderId" to order.optString("id"), "recognized" to recognized))
            }
            normalized.contains("repeat") || normalized.contains("dobara") || normalized.contains("फिर") -> {
                sendResultToFlutter("REPEAT", mapOf("orderId" to order.optString("id")))
            }
            else -> {
                sendResultToFlutter("UNKNOWN", mapOf("orderId" to order.optString("id"), "recognized" to recognized))
            }
        }
    }

    private fun isNoisyEnvironment(): Boolean {
        try {
            audioRecorder = AudioRecord(
                MediaRecorder.AudioSource.MIC,
                16000,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
                audioBufferSize
            )
            audioRecorder?.startRecording()
            val buffer = ShortArray(1024)
            var totalRms = 0.0
            var samples = 0
            val start = System.currentTimeMillis()
            while (System.currentTimeMillis() - start < 700) {
                val read = audioRecorder?.read(buffer, 0, buffer.size) ?: 0
                if (read > 0) {
                    var sum = 0.0
                    for (i in 0 until read) {
                        sum += (buffer[i] * buffer[i]).toDouble()
                    }
                    val rms = kotlin.math.sqrt(sum / read)
                    if (rms > 0) {
                        totalRms += 20 * log10(rms)
                        samples++
                    }
                }
            }
            audioRecorder?.stop()
            audioRecorder?.release()
            audioRecorder = null
            val avg = if (samples > 0) totalRms / samples else 0.0
            Log.d(TAG, "Noise dB avg=$avg")
            return avg > noiseThresholdDb
        } catch (e: Exception) {
            Log.w(TAG, "Noise detection failed", e)
            return false
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val chan = NotificationChannel(CHANNEL_ID, "Eatzy Voice", NotificationManager.IMPORTANCE_HIGH).apply {
                description = "Eatzy vendor voice notifications"
                setSound(null, null)
            }
            nm.createNotificationChannel(chan)
        }
    }

    private fun buildNotification(content: String): Notification {
        val notifIntent = Intent(this, MainActivity::class.java)
        val pIntent = PendingIntent.getActivity(this, 0, notifIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Eatzy")
            .setContentText(content)
            .setSmallIcon(R.drawable.ic_stat_eatzy)
            .setContentIntent(pIntent)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .build()
    }

    private fun acquireWakeLock() {
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "eatzy:voiceWakelock")
        wakeLock?.acquire(10 * 60 * 1000L) // 10 minutes max
    }

    private fun releaseWakeLock() {
        try {
            wakeLock?.let { if (it.isHeld) it.release() }
        } catch (e: Exception) { }
    }

    private fun sendResultToFlutter(type: String, payload: Map<String, Any?>) {
        val intent = Intent("com.eatzy.eatzy_vendor.VOICE_RESULT")
        intent.putExtra("type", type)
        intent.putExtra("payload", JSONObject(payload as Map<*, *>).toString())
        sendBroadcast(intent)
    }

    override fun onDestroy() {
        super.onDestroy()
        tts?.shutdown()
        speechRecognizer?.destroy()
        mediaPlayer?.release()
        serviceScope.cancel()
    }

    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            tts?.language = Locale("en", "US")
        } else {
            Log.w(TAG, "TTS init failed")
        }
    }

    companion object {
        fun startServiceWithOrder(context: Context, orderJson: String) {
            val intent = Intent(context, EatzyForegroundService::class.java)
            intent.action = ACTION_START
            intent.putExtra(EXTRA_ORDER, orderJson)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
    }
}
