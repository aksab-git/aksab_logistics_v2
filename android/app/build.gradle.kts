import java.util.Properties

// 1. جلب بيانات الإصدار من ملف local.properties
val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}

val flutterVersionCode = localProperties.getProperty("flutter.versionCode") ?: "1"
val flutterVersionName = localProperties.getProperty("flutter.versionName") ?: "1.0.0"

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.aksab.logistics_v2"
    compileSdk = flutter.compileSdkVersion

    defaultConfig {
        applicationId = "com.aksab.logistics_v2"
        minSdk = 21
        targetSdk = flutter.targetSdkVersion
        versionCode = flutterVersionCode.toInt()
        versionName = flutterVersionName
        multiDexEnabled = true
    }

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        freeCompilerArgs = freeCompilerArgs + "-Xjdk-release=1.8"
    }
}

dependencies {
    // تم التحديث لنسخة 2.1.4 بناءً على طلب Gradle
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
