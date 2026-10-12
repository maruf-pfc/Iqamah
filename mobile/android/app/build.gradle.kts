plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Preserved package identity for upgrade continuity across versions
        applicationId = "com.example.mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Never silently produce a public release signed with a debug certificate.
            // The previous distribution certificate must be verified before providing these values.
            val keyPath = System.getenv("IQAMAH_KEYSTORE_PATH")
            if (!keyPath.isNullOrBlank()) {
                val releaseSigning = signingConfigs.create("release") {
                    storeFile = file(keyPath)
                    storePassword = System.getenv("IQAMAH_STORE_PASSWORD")
                    keyAlias = System.getenv("IQAMAH_KEY_ALIAS")
                    keyPassword = System.getenv("IQAMAH_KEY_PASSWORD")
                }
                signingConfig = releaseSigning
            }
        }
    }
}

gradle.taskGraph.whenReady {
    if (allTasks.any { it.name.contains("Release") } &&
        listOf("IQAMAH_KEYSTORE_PATH", "IQAMAH_STORE_PASSWORD", "IQAMAH_KEY_ALIAS", "IQAMAH_KEY_PASSWORD").any { System.getenv(it).isNullOrBlank() }) {
        throw GradleException("Release blocked: supply the existing verified signing identity via IQAMAH_* environment variables. Debug signing is not a release fallback.")
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
