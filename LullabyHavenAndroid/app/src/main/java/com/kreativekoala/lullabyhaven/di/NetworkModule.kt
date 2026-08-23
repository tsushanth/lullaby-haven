package com.kreativekoala.lullabyhaven.di

import com.kreativekoala.lullabyhaven.BuildConfig
import com.kreativekoala.lullabyhaven.data.DeviceIdProvider
import com.kreativekoala.lullabyhaven.data.api.VoiceApi
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import okhttp3.Interceptor
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import java.util.concurrent.TimeUnit
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {

    /**
     * listenai-backend requires an `X-Device-ID` header on /api/cloned-voices and
     * /api/stories (400 without it -- there's no user auth system in this app yet, so the
     * device ID is the only identity the backend has). /api/tts and /api/tts/job-cloned use
     * Bearer auth instead but tolerate a missing/empty token by falling back to a default
     * "pro" user server-side, so no Authorization header is required for those to work.
     */
    @Provides
    @Singleton
    fun provideDeviceIdInterceptor(deviceIdProvider: DeviceIdProvider): Interceptor =
        Interceptor { chain ->
            val request = chain.request().newBuilder()
                .addHeader("X-Device-ID", deviceIdProvider.deviceId)
                .build()
            chain.proceed(request)
        }

    @Provides
    @Singleton
    fun provideOkHttpClient(deviceIdInterceptor: Interceptor): OkHttpClient {
        val logging = HttpLoggingInterceptor().apply {
            level = if (BuildConfig.DEBUG) {
                HttpLoggingInterceptor.Level.BODY
            } else {
                HttpLoggingInterceptor.Level.NONE
            }
        }
        return OkHttpClient.Builder()
            .addInterceptor(deviceIdInterceptor)
            .addInterceptor(logging)
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(60, TimeUnit.SECONDS)
            .writeTimeout(60, TimeUnit.SECONDS)
            .build()
    }

    @Provides
    @Singleton
    fun provideRetrofit(client: OkHttpClient): Retrofit {
        return Retrofit.Builder()
            .baseUrl("${BuildConfig.API_BASE_URL}/")
            .client(client)
            .addConverterFactory(GsonConverterFactory.create())
            .build()
    }

    @Provides
    @Singleton
    fun provideVoiceApi(retrofit: Retrofit): VoiceApi = retrofit.create(VoiceApi::class.java)
}
