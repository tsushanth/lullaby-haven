plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.hilt)
    alias(libs.plugins.ksp)
}

android {
    namespace = "com.kreativekoala.lullabyhaven"
    compileSdk = 36

    signingConfigs {
        create("release") {
            storeFile = file("/Users/sushanthtiruvaipati/Documents/GitHub/AndroidAppKey")
            storePassword = "REMOVED-CREDENTIAL"
            keyAlias = "androidappkey"
            keyPassword = "REMOVED-CREDENTIAL"
        }
    }

    defaultConfig {
        applicationId = "com.kreativekoala.lullabyhaven"
        minSdk = 26
        targetSdk = 36
        versionCode = 1
        versionName = "1.0.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        vectorDrawables {
            useSupportLibrary = true
        }

        // TODO: wire real backend base URL(s) once credentials/infra are confirmed for Android.
        // iOS talks to https://listenai-backend.fly.dev for cloned-voice + story-generation +
        // TTS job endpoints (this is the SAME backend that powers Audexa/ReadAloud voice
        // cloning + Kokoro TTS on the shared Hetzner box) -- do not point this at a new backend.
        buildConfigField("String", "API_BASE_URL", "\"https://listenai-backend.fly.dev\"")
    }

    buildTypes {
        debug {
            isDebuggable = true
        }
        release {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("release")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }

    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

dependencies {
    // Core Android
    implementation(libs.androidx.core.ktx)
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation(libs.androidx.lifecycle.runtime.ktx)
    implementation(libs.androidx.lifecycle.viewmodel.compose)
    implementation(libs.androidx.activity.compose)

    // Compose
    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.ui)
    implementation(libs.androidx.ui.graphics)
    implementation(libs.androidx.ui.tooling.preview)
    implementation(libs.androidx.material3)
    implementation(libs.androidx.material.icons.extended)
    implementation(libs.androidx.navigation.compose)
    debugImplementation(libs.androidx.ui.tooling)

    // Hilt
    implementation(libs.hilt.android)
    ksp(libs.hilt.compiler)
    implementation(libs.hilt.navigation.compose)

    // Networking
    implementation(libs.retrofit)
    implementation(libs.retrofit.converter.gson)
    implementation(libs.okhttp)
    implementation(libs.okhttp.logging)

    // Coroutines
    implementation(libs.kotlinx.coroutines.android)

    // DataStore
    implementation(libs.datastore.preferences)

    // Room
    implementation(libs.room.runtime)
    implementation(libs.room.ktx)
    ksp(libs.room.compiler)

    // Media3 / ExoPlayer (bedtime story + sound playback)
    implementation(libs.media3.exoplayer)
    implementation(libs.media3.ui)
    implementation(libs.media3.session)

    // Image Loading
    implementation(libs.coil.compose)

    // Accompanist (mic permission handling)
    implementation(libs.accompanist.permissions)

    // PaywallKit (shared subscription/paywall UI across the portfolio)
    implementation(project(":paywallkit"))

    // RatingKit (Play In-App Review wrapper, matches iOS review-prompt behavior)
    implementation(project(":ratingkit"))

    // Testing
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
    androidTestImplementation(platform(libs.androidx.compose.bom))
    androidTestImplementation("androidx.compose.ui:ui-test-junit4")
    debugImplementation("androidx.compose.ui:ui-test-manifest")
}
