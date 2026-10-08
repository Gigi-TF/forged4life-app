import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

/*
 * Signing details, read from android/key.properties.
 *
 * That file holds real passwords and is gitignored — which is why this reads
 * it rather than hardcoding anything. The `exists()` check means a checkout
 * without it can still build a debug APK.
 */
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "org.skillsforge360.forged4life"

    // Pinned rather than read from Flutter's default. 36 because plugins in
    // the tree require it, and pinning means a Flutter upgrade cannot quietly
    // move it.
    compileSdk = 36

    // Commented out because the NDK will not install on this machine and
    // nothing in the dependency tree actually needs it.
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

        targetSdk = 36

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")

            /*
             * Off, deliberately.
             *
             * R8 strips code it believes is unreachable, and this app reaches
             * plenty of things reflectively through plugins. Turning it on is
             * worth doing later, with a release APK tested on a real phone
             * first — not on the build that goes to Play unverified.
             */
            isMinifyEnabled = false
            isShrinkResources = false
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
