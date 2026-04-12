import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.kapt")
    id("org.jetbrains.kotlin.plugin.serialization")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

// Load local.properties explicitly so keys like GEMINI_API_KEY can be kept
// out of the tracked gradle.properties. Gradle only auto-exposes `sdk.dir`
// from local.properties — anything else has to be read manually.
val localProps = Properties().apply {
    val f = rootProject.file("local.properties")
    if (f.exists()) f.inputStream().use(::load)
}
fun localOrProject(key: String): String? =
    localProps.getProperty(key) ?: project.findProperty(key) as String?

android {
    namespace = "com.foodsense.android"
    compileSdk = 34
    assetPacks += listOf(":model_pack")

    defaultConfig {
        applicationId = "com.foodsense.android"
        minSdk = 26
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"

        // Production: set PROXY_BASE_URL in gradle.properties to your Firebase Functions URL
        val proxyUrl = localOrProject("PROXY_BASE_URL") ?: ""
        buildConfigField("String", "PROXY_BASE_URL", "\"$proxyUrl\"")

        // Legacy fallback: GEMINI_API_KEY from local.properties is used only if the user
        // has not configured a key via Settings > AI Configuration.  New installs should
        // use the in-app API key entry (EncryptedSharedPreferences) instead.
        val geminiKey = localOrProject("GEMINI_API_KEY") ?: ""
        buildConfigField("String", "GEMINI_API_KEY", "\"$geminiKey\"")

        // Social features API base URL
        val socialApiUrl = localOrProject("SOCIAL_API_BASE_URL") ?: ""
        buildConfigField("String", "SOCIAL_API_BASE_URL", "\"$socialApiUrl\"")
    }

    signingConfigs {
        create("release") {
            // Set these in gradle.properties or local.properties (git-ignored):
            //   RELEASE_STORE_FILE=/path/to/foodsense-release.keystore
            //   RELEASE_STORE_PASSWORD=...
            //   RELEASE_KEY_ALIAS=...
            //   RELEASE_KEY_PASSWORD=...
            val storeFilePath = project.findProperty("RELEASE_STORE_FILE") as String?
            if (storeFilePath != null) {
                storeFile = file(storeFilePath)
                storePassword = project.findProperty("RELEASE_STORE_PASSWORD") as String?
                keyAlias = project.findProperty("RELEASE_KEY_ALIAS") as String?
                keyPassword = project.findProperty("RELEASE_KEY_PASSWORD") as String?
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            isDebuggable = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("release")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    kotlinOptions {
        jvmTarget = "11"
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }

    composeOptions {
        kotlinCompilerExtensionVersion = "1.4.8"
    }

    packagingOptions {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.6.2")
    implementation("androidx.activity:activity-compose:1.7.2")

    implementation("androidx.compose.ui:ui:1.4.3")
    implementation("androidx.compose.ui:ui-tooling-preview:1.4.3")
    implementation("androidx.compose.foundation:foundation:1.4.3")
    implementation("androidx.compose.material3:material3:1.1.1")
    implementation("androidx.compose.material:material-icons-extended:1.4.3")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.6.2")
    implementation("com.google.android.material:material:1.11.0")

    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.5.1")
    implementation("com.squareup.okhttp3:okhttp:4.12.0")

    implementation("androidx.camera:camera-core:1.3.1")
    implementation("androidx.camera:camera-camera2:1.3.1")
    implementation("androidx.camera:camera-lifecycle:1.3.1")
    implementation("androidx.camera:camera-view:1.3.1")

    implementation("org.tensorflow:tensorflow-lite:2.14.0")
    implementation("org.tensorflow:tensorflow-lite-support:0.4.4")

    // ML Kit Barcode Scanning
    implementation("com.google.mlkit:barcode-scanning:17.2.0")

    // Room
    implementation("androidx.room:room-runtime:2.6.1")
    implementation("androidx.room:room-ktx:2.6.1")
    kapt("androidx.room:room-compiler:2.6.1")

    // Glance AppWidget
    implementation("androidx.glance:glance-appwidget:1.0.0")

    // Health Connect
    implementation("androidx.health.connect:connect-client:1.1.0-alpha07")

    // Encrypted storage for user API keys
    implementation("androidx.security:security-crypto:1.1.0-alpha06")

    // On-device LiteRT-LM for Gemma inference (uncomment when dependency is published)
    // implementation("com.google.ai.edge.litert:litert-lm:+")

    // Firebase
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    implementation("com.google.firebase:firebase-auth-ktx")
    implementation("com.google.firebase:firebase-crashlytics-ktx")
    implementation("com.google.firebase:firebase-analytics-ktx")

    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
    androidTestImplementation("androidx.compose.ui:ui-test-junit4:1.4.3")
    debugImplementation("androidx.compose.ui:ui-tooling:1.4.3")
    debugImplementation("androidx.compose.ui:ui-test-manifest:1.4.3")
}
