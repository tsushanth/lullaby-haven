package com.kreativekoala.lullabyhaven.di

import android.content.Context
import androidx.room.Room
import com.kreativekoala.lullabyhaven.data.local.AppDatabase
import com.kreativekoala.lullabyhaven.data.local.FavoriteStoryDao
import com.kreativekoala.lullabyhaven.data.local.OwnRecordingDao
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {

    @Provides
    @Singleton
    fun provideAppDatabase(@ApplicationContext context: Context): AppDatabase =
        Room.databaseBuilder(context, AppDatabase::class.java, "lullaby_haven.db").build()

    @Provides
    fun provideOwnRecordingDao(db: AppDatabase): OwnRecordingDao = db.ownRecordingDao()

    @Provides
    fun provideFavoriteStoryDao(db: AppDatabase): FavoriteStoryDao = db.favoriteStoryDao()
}
