plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.freezone.employee_affairs"
    // نثبت 34 مؤقتاً لأن android-35/36 غير مثبتين عندك
    // وsdkmanager CLI يتعطل — ثبّتي Platform من Android Studio ثم ارفعي الرقم لاحقاً.
    compileSdk = 34
    // نثبت نفس إصدار Flutter NDK محلياً عبر stub/تثبيت Studio
    // حتى لا يستدعي Gradle sdkmanager المعطوب عندك.
    ndkVersion = "28.2.13676358"
    // التطبيق حالياً واجهات فقط؛ الـ stub يكفي للتشغيل التجريبي.

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.freezone.employee_affairs"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 34
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // تأكيد تضمين مكتبات Flutter native داخل الـ APK (مهم للمحاكي x86_64)
        ndk {
            abiFilters += listOf("armeabi-v7a", "arm64-v8a", "x86_64")
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // تجنّب llvm-strip + ضمان استخراج .so بشكل صحيح على المحاكي
    packaging {
        jniLibs {
            keepDebugSymbols += "**/*.so"
            useLegacyPackaging = true
        }
    }
}

// عطّل مهمة strip إن ظهرت — تفشل إذا NDK غير مكتمل التثبيت
tasks.configureEach {
    if (name.contains("stripDebugDebugSymbols", ignoreCase = true) ||
        name.contains("stripReleaseDebugSymbols", ignoreCase = true)
    ) {
        enabled = false
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
