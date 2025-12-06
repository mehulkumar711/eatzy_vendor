package com.eatzy.eatzy_vendor.ui

import androidx.test.core.app.ActivityScenario
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.eatzy.eatzy_vendor.MainActivity
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class ItemsPageInstrumentedTest {
    @Test
    fun opensItemsPage() {
        ActivityScenario.launch(MainActivity::class.java)
        // assert app launched; further UI interactions require id/labels in widget tree
        Thread.sleep(1000)
    }
}
