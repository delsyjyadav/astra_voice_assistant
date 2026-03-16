plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.astra_voice_assistant"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {

        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.astra_voice_assistant"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }


    packagingOptions {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
        pickFirsts += listOf(
            "lib/x86/libc++_shared.so",
            "lib/x86_64/libc++_shared.so",
            "lib/armeabi-v7a/libc++_shared.so",
            "lib/arm64-v8a/libc++_shared.so"
        )
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    packagingOptions {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
        pickFirsts += listOf(
            "lib/x86/libc++_shared.so",
            "lib/x86_64/libc++_shared.so",
            "lib/armeabi-v7a/libc++_shared.so",
            "lib/arm64-v8a/libc++_shared.so"
        )
    }
}


dependencies {

    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

flutter {
    source = "../.."
}
