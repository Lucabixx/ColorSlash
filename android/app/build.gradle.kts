import java.util.Properties
import java.io.FileInputStream
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") version "4.4.3" // Google services si applica QUI
    id("com.google.firebase.crashlytics") version "3.0.6"

}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "app.lucabixx.colorslash"
    compileSdk = 36

    defaultConfig {
        applicationId = "app.lucabixx.colorslash"
        minSdk = 21
        targetSdk = 36
        versionCode = 1
        versionName = "0.1"
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            storeFile = file(keystoreProperties["storeFile"] ?: "keystore.jks")
            storePassword = keystoreProperties["storePassword"] as String? ?: "140596"
            keyAlias = keystoreProperties["keyAlias"] as String? ?: "upload"
            keyPassword = keystoreProperties["keyPassword"] as String? ?: "140596"
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            minifyEnabled = false
            shrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        getByName("debug") {
            minifyEnabled = false
            shrinkResources = false
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin {
        jvmToolchain(17)
        compilerOptions {
            jvmTarget.set(JvmTarget.JVM_17)
        }
    }

    buildFeatures {
        viewBinding = true
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
    implementation("org.jetbrains.kotlin:kotlin-stdlib:2.2.20")
}



