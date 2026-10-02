plugins {
    id("com.android.application")
    kotlin("android")
}

android {
    namespace = "me.x.shizukuax"
    compileSdk = 34
    defaultConfig {
        minSdk = 23
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }
    buildTypes {
        getByName("debug") {
            isMinifyEnabled = false
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.11.0")
    implementation("androidx.webkit:webkit:1.9.0")
    implementation("org.json:json:20230227")
}
