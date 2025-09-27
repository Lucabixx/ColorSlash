import java.util.Properties
import java.io.FileInputStream
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") version "4.4.3" // Google Services
    id("com.google.firebase.crashlytics") version "3.0.6" // Crashlytics
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
            storePassword = keystoreProperties["storePassword"]?.toString() ?: "140596"
            keyAlias = keystoreProperties["keyAlias"]?.toString() ?: "upload"
            keyPassword = keystoreProperties["keyPassword"]?.toString() ?: "140596"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }

        debug {
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // Opzione Kotlin (forma classica)
    kotlinOptions {
        jvmTarget = "17"
    }

    // Alternativa moderna (opzionale, decommenta se vuoi)
    /*
    kotlin {
        compilerOptions {
            jvmTarget.set(JvmTarget.JVM_17)
        }
    }
    */

    buildFeatures {
        viewBinding = true
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Flutter / Kotlin / Multidex
    implementation("androidx.multidex:multidex:2.0.1")
    implementation("org.jetbrains.kotlin:kotlin-stdlib:2.0.21")

    // Firebase (Crashlytics + Analytics)
    implementation(platform("com.google.firebase:firebase-bom:33.1.2"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-crashlytics")
}
