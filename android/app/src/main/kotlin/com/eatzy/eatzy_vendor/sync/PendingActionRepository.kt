package com.eatzy.eatzy_vendor.sync

import android.content.Context
import android.util.Log
import android.content.Intent
import com.eatzy.eatzy_vendor.db.PendingAction
import com.eatzy.eatzy_vendor.db.PendingActionDao
import com.eatzy.eatzy_vendor.net.ApiService
import org.json.JSONObject
import kotlin.random.Random
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager

class PendingActionRepository(
    private val context: Context,
    private val api: ApiService,
    private val dao: PendingActionDao
) {
    private val TAG = "PendingActionRepo"
    private val baseBackoffMs = 2000L

    // No internal polling loop anymore. Using WorkManager.

    suspend fun addOrUpdate(action: PendingAction) {
        dao.upsert(action)
        notifyEvent("ACTION_CREATED", action)
        scheduleWorkerImmediate()
    }

    suspend fun getAll(): List<PendingAction> = dao.getAll()

    suspend fun processDueOnce() {
        val now = System.currentTimeMillis()
        val due = dao.getDue(now)
        for (pa in due) {
            try {
                // If attempt count is high, stop trying
                if (pa.attempts > 10) {
                     // Optionally delete or mark as PERMANENT_FAILURE
                    continue
                }
                
                Log.d(TAG, "Processing action ${pa.uuid}: ${pa.action}")
                val success = executeAction(pa)
                if (success) {
                    dao.deleteByUuid(pa.uuid)
                    notifyEvent("ACTION_SUCCEEDED", pa)
                    Log.d(TAG, "Action ${pa.uuid} succeeded")
                } else {
                    val attempts = pa.attempts + 1
                    val backoff = computeBackoff(attempts)
                    val nextAt = System.currentTimeMillis() + backoff
                    val updated = pa.copy(attempts = attempts, nextTryAt = nextAt)
                    dao.upsert(updated)
                    notifyEvent("ACTION_RETRY", updated)
                    Log.d(TAG, "Action ${pa.uuid} failed, retry in ${backoff}ms")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error processing action ${pa.uuid}", e)
                val attempts = pa.attempts + 1
                val backoff = computeBackoff(attempts)
                val nextAt = System.currentTimeMillis() + backoff
                val updated = pa.copy(attempts = attempts, nextTryAt = nextAt)
                dao.upsert(updated)
                notifyEvent("ACTION_ERROR", updated)
            }
        }
    }

    private suspend fun executeAction(pa: PendingAction): Boolean {
        return try {
            when (pa.action) {
                "accept" -> api.acceptOrder(pa.orderId).isSuccessful
                "reject" -> api.rejectOrder(pa.orderId).isSuccessful
                "ready" -> api.readyOrder(pa.orderId).isSuccessful
                "payment" -> {
                    val body = parsePayload(pa.payloadJson)
                    api.payment(pa.orderId, body).isSuccessful
                }
                else -> false
            }
        } catch (e: Exception) {
            Log.e(TAG, "Network calc failed", e)
            false
        }
    }

    private fun parsePayload(json: String): Map<String, Any> {
        return try {
            val jsonObject = JSONObject(json)
            val map = mutableMapOf<String, Any>()
            val keys = jsonObject.keys()
            while (keys.hasNext()) {
                val key = keys.next()
                map[key] = jsonObject.get(key)
            }
            map
        } catch (e: Exception) {
            emptyMap()
        }
    }

    private fun computeBackoff(attempts: Int): Long {
        val exp = baseBackoffMs * (1L shl (attempts.coerceAtMost(6)))
        val jitter = Random.nextLong(0, baseBackoffMs)
        return exp + jitter
    }

    private fun notifyEvent(event: String, pa: PendingAction) {
        val intent = Intent("com.eatzy.eatzy_vendor.PENDING_ACTION_EVENT")
        intent.putExtra("event", event)
        val payloadMap = mapOf(
            "uuid" to pa.uuid,
            "action" to pa.action,
            "orderId" to pa.orderId,
            "attempts" to pa.attempts,
            "nextTryAt" to pa.nextTryAt
        )
        intent.putExtra("payload", JSONObject(payloadMap).toString())
        context.sendBroadcast(intent)
    }

    fun scheduleWorkerImmediate() {
        val work = OneTimeWorkRequestBuilder<PendingActionWorker>().build()
        WorkManager.getInstance(context).enqueue(work)
    }
}
