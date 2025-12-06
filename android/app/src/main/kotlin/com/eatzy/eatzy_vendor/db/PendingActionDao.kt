package com.eatzy.eatzy_vendor.db

import androidx.room.*

@Dao
interface PendingActionDao {

    @Query("SELECT * FROM pending_actions ORDER BY nextTryAt ASC, createdAt ASC")
    suspend fun getAll(): List<PendingAction>

    @Query("SELECT * FROM pending_actions WHERE uuid = :uuid LIMIT 1")
    suspend fun getByUuid(uuid: String): PendingAction?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(action: PendingAction)

    @Delete
    suspend fun delete(action: PendingAction)

    @Query("DELETE FROM pending_actions WHERE uuid = :uuid")
    suspend fun deleteByUuid(uuid: String)

    @Query("SELECT * FROM pending_actions WHERE nextTryAt <= :now")
    suspend fun getDue(now: Long): List<PendingAction>
}
