package com.eatzy.eatzy_vendor.db

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "pending_actions")
data class PendingAction(
    @PrimaryKey val uuid: String,          // unique id
    val action: String,                    // "accept", "reject", "ready", "payment"
    val orderId: String,
    val payloadJson: String,               // minimal JSON (stringified)
    val attempts: Int = 0,
    val nextTryAt: Long = 0L,              // epoch millis
    val createdAt: Long = System.currentTimeMillis()
)
