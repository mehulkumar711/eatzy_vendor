package com.eatzy.eatzy_vendor.sync

import android.content.Context
import android.util.Log
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.eatzy.eatzy_vendor.db.AppDatabase
import com.eatzy.eatzy_vendor.net.ApiService
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

private const val TAG = "PendingActionWorker"

class PendingActionWorker(
    private val ctx: Context,
    params: WorkerParameters
) : CoroutineWorker(ctx, params) {

    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
        try {
            val db = AppDatabase.getInstance(ctx)
            val dao = db.pendingActionDao()
            val due = dao.getDue(System.currentTimeMillis())
            if (due.isEmpty()) {
                // nothing to do
                return@withContext Result.success()
            }
            // In production, use BuildConfig.EATZY_API_BASE_URL
            val api = ApiService.create("http://10.0.2.2:3000/")
            // We create a fresh repository instance just for this pass
            val repo = PendingActionRepository(ctx, api, dao)
            repo.processDueOnce() // single pass (blocking)
            return@withContext Result.success()
        } catch (t: Throwable) {
            Log.e(TAG, "worker error", t)
            return@withContext Result.retry()
        }
    }
}
