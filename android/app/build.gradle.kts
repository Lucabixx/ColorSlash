plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") version "4.4.3" // Google services si applica QUI
    id("com.google.firebase.crashlytics") version "3.0.6" // Crashlytics qui
}

android {
    namespace = "app.lucabixx.colorslash"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
	    
signingConfigs {
    create("release") {
        storeFile = file("../keystore.jks")
        storePassword = "140596"
        keyAlias = "upload"
        keyPassword = "140596"
        is MinifyEnabled = false
        isShrinkResources = false
    }
}

    defaultConfig {
        applicationId = "app.lucabixx.colorslash"
        minSdk = flutter.minSdkVersion // o flutter.minSdkVersion se lo leggi da gradle.properties
		targetSdk = 36
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
        multiDexEnabled = true
    }
// }

flutter {
    source = "../.."
 }

}
