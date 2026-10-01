import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// مفتاح الرفع الخاص بالمؤسسة يُقرأ من android/key.properties؛ الملف والمفتاح لا يدخلان Git أبداً:
//   storePassword=...
//   keyPassword=...
//   keyAlias=upload
//   storeFile=C:/Users/<user>/upload-keystore.jks
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        FileInputStream(keystorePropertiesFile).use { load(it) }
    }
}
// معالج «Generate Signed Bundle» في Android Studio يمرّر مفتاحه بنفسه.
val hasUploadKey = keystorePropertiesFile.exists() ||
    project.hasProperty("android.injected.signing.store.file")

android {
    namespace = "com.freezone.employee_affairs"

    compileSdk = 36
    // مطلوب لأن Flutter يحدد هذا الإصدار؛ نضع stub محلي أو NDK حقيقي من Android Studio
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.freezone.employee_affairs"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // بدون مفتاح الرفع تُوقَّع ملفات APK بمفتاح debug للتجربة المحلية فقط، وتُرفض حزمة Play أدناه.
            signingConfig = signingConfigs.getByName(
                if (keystorePropertiesFile.exists()) "release" else "debug",
            )
        }
    }

    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

gradle.taskGraph.whenReady {
    if (!hasUploadKey) {
        if (allTasks.any { it.name == "bundleRelease" }) {
            throw GradleException(
                "Google Play bundles must be signed with the organization's upload key. " +
                    "Create android/key.properties as described at the top of android/app/build.gradle.kts.",
            )
        }
        if (allTasks.any { it.name == "assembleRelease" }) {
            // Flutter يشغّل Gradle بالخيار -q الذي يُخفي رسائل logger.warn.
            logger.quiet(
                "Warning: android/key.properties not found, so this release APK is signed with the " +
                    "local debug key. Use it for local testing only; it can't be uploaded to Google Play.",
            )
        }
    }
}
