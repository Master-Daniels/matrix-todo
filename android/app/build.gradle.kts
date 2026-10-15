import java.io.File
import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing: loads untracked android/key.properties locally and
// KEYSTORE_* env vars on CI. Falls back to debug keys so
// `flutter run --release` still works without secrets.
val keystoreProps = Properties()
val keystorePropsFile = rootProject.file("key.properties")
if (keystorePropsFile.exists()) {
    FileInputStream(keystorePropsFile).use { keystoreProps.load(it) }
}

android {
    namespace = "com.masterdaniels.matrixtodo"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required by flutter_local_notifications (Java 8+ APIs on older runtimes).
        isCoreLibraryDesugaringEnabled = true
    }

    dependencies {
        coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    }

    defaultConfig {
        applicationId = "com.masterdaniels.matrixtodo"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 37
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val storeFileProp =
                (System.getenv("KEYSTORE_FILE")
                    ?: keystoreProps.getProperty("storeFile")?.takeIf { it.isNotBlank() })
            // KEYSTORE_FILE may be absolute (CI) or relative to the app
            // module dir (local key.properties) or android/ dir.
            val storeFileResolved = storeFileProp?.let {
                val f = File(it)
                if (f.isAbsolute) f
                else projectDir.resolve(it).takeIf { it.exists() }
                    ?: rootProject.file(it)
            }
            if (storeFileResolved != null && storeFileResolved.exists()) {
                storeFile = storeFileResolved
                storePassword =
                    System.getenv("KEYSTORE_PASSWORD")
                        ?: keystoreProps.getProperty("storePassword")
                keyAlias =
                    System.getenv("KEY_ALIAS")
                        ?: keystoreProps.getProperty("keyAlias")
                keyPassword =
                    System.getenv("KEY_PASSWORD")
                        ?: keystoreProps.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Uses the "release" signing config when key.properties / CI env
            // is present, otherwise falls back to debug keys.
            val releaseSigning = signingConfigs.findByName("release")
            val hasStore =
                try {
                    releaseSigning?.storeFile?.exists() == true
                } catch (_: Exception) {
                    false
                }
            signingConfig =
                if (hasStore) signingConfigs.getByName("release")
                else signingConfigs.getByName("debug")
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
