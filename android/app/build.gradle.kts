plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "org.skillsforge360.forged4life"

    // Pinned rather than read from Flutter's default. Play requires 35 for
    // new apps, and pinning means a Flutter upgrade cannot quietly move it.
    compileSdk = 36

    //ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Never changes after publishing — a different id is a different app,
        // with no upgrade path for anyone who installed the first one.
        applicationId = "org.skillsforge360.forged4life"

        // 23 is the floor for flutter_secure_storage's EncryptedSharedPreferences.
        // Below it the card secret has nowhere safe to live, which is the one
        // thing this app cannot compromise on.
        minSdk = flutter.minSdkVersion

        targetSdk = 35

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Debug keys, so `flutter run --release` works while testing.
            // Replace with the real keystore before building for Play.
            signingConfig = signingConfigs.getByName("debug")
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
