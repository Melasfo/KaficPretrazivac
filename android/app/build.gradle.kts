plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // Add the Google services Gradle plugin
}

android {
    namespace = "com.example.kafic_pretrazivac"
    compileSdk = 34
    ndkVersion = "27.0.12077973"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8" // Use Java 8 for Kotlin
    }

    defaultConfig {
        applicationId = "com.example.kafic_pretrazivac"
        minSdk = 23
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            // Use the debug signing configuration for release builds
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Import the Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:33.6.0"))
    // Enable core library desugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:1.2.2")
    // Example Firebase dependencies
    // implementation("com.google.firebase:firebase-auth-ktx")
    // implementation("com.google.firebase:firebase-firestore-ktx")
}
