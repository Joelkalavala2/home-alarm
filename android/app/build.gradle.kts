plugins {
    id "com.android.application"
    id "dev.flutter.flutter-gradle-plugin"
    id "org.jetbrains.kotlin.android"
}

android {
    namespace "com.example.myapp"
    compileSdk flutter.compileSdkVersion
    ndkVersion flutter.ndkVersion

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = '1.8'
    }

    sourceSets {
        main.java.srcDirs += 'src/main/kotlin'
    }

    defaultConfig {
        applicationId "com.example.myapp"
        minSdk flutter.minSdkVersion
        targetSdk flutter.targetSdkVersion
        versionCode 1
        versionName "1.0"
    }

    buildTypes {
        release {
            signingConfig signingConfigs.debug
        }
    }
}

flutter {
    source '../..'
}

dependencies {}
