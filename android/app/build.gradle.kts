plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.freezone.employee_affairs"
    compileSdk = 34
    // مطلوب لأن Flutter يحدد هذا الإصدار؛ نضع stub محلي أو NDK حقيقي من Android Studio
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.freezone.employee_affairs"
        minSdk = flutter.minSdkVersion
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    packaging {
        jniLibs {
            // لا تُفرَّغ مكتبات Flutter أثناء التعبئة
            keepDebugSymbols += listOf("**/*.so")
            useLegacyPackaging = true
        }
    }
}

// امنع strip من إتلاف libflutter.so إذا كان llvm-strip غير حقيقي
tasks.configureEach {
    if (name.contains("strip", ignoreCase = true) && name.contains("DebugSymbols", ignoreCase = true)) {
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
