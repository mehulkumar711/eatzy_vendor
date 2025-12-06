package com.eatzy.eatzy_vendor.net

import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Response
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import retrofit2.http.POST
import retrofit2.http.Path
import retrofit2.http.Body
import java.util.concurrent.TimeUnit

interface ApiService {

    @POST("orders/{id}/accept")
    suspend fun acceptOrder(@Path("id") orderId: String): Response<Map<String, Any>>

    @POST("orders/{id}/reject")
    suspend fun rejectOrder(@Path("id") orderId: String): Response<Map<String, Any>>

    @POST("orders/{id}/ready")
    suspend fun readyOrder(@Path("id") orderId: String): Response<Map<String, Any>>

    @POST("orders/{id}/payment")
    suspend fun payment(@Path("id") orderId: String, @Body body: Map<String, Any>): Response<Map<String, Any>>

    companion object {
        fun create(baseUrl: String): ApiService {
            val logging = HttpLoggingInterceptor().apply { level = HttpLoggingInterceptor.Level.BASIC }
            val client = OkHttpClient.Builder()
                .addInterceptor(logging)
                .connectTimeout(15, TimeUnit.SECONDS)
                .readTimeout(15, TimeUnit.SECONDS)
                .build()

            val retrofit = Retrofit.Builder()
                .baseUrl(baseUrl)
                .client(client)
                .addConverterFactory(GsonConverterFactory.create())
                .build()

            return retrofit.create(ApiService::class.java)
        }
    }
}
