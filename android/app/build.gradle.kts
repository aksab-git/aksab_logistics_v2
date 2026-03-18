import java.util.Properties

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

android {
    // تأكد أن هذا الـ Namespace هو المعتمد لمشروعك
    namespace = "com.aksab.sales"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.aksab.sales"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // إنشاء إعدادات التوقيع بشكل آمن (لا يسبب خطأ لو الملف غير موجود)
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as? String
                keyPassword = keystoreProperties["keyPassword"] as? String
                val storeFilePath = keystoreProperties["storeFile"] as? String
                storeFile = if (storeFilePath != null) file(storeFilePath) else null
                storePassword = keystoreProperties["storePassword"] as? String
            }
        }
    }

    buildTypes {
        release {
            // لو ملف المفاتيح موجود استخدم التوقيع الرسمي، لو مش موجود استخدم الـ debug
            signingConfig = if (keystorePropertiesFile.exists() && keystoreProperties["storeFile"] != null) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            
            isMinifyEnabled = false
            isShrinkResources = false
        }
        
        debug {
            // نسخة التجربة دايماً بتستخدم توقيع أندرويد الافتراضي
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

