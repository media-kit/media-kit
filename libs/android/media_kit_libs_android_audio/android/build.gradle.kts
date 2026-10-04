import java.io.File
import java.net.URI
import java.security.MessageDigest

group = "com.alexmercerind.media_kit_libs_android_audio"
version = "1.0"

buildscript {
    val kotlinVersion = "2.4.0"
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:8.13.2")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

plugins {
    id("com.android.library")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

android {
    namespace = "com.alexmercerind.media_kit_libs_android_audio"
    compileSdk = flutter.compileSdkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        minSdk = 24
    }
}

dependencies {
    implementation(fileTree(layout.buildDirectory.dir("output")) { include("*.jar") })
}

fun File.md5(): String {
    val digest = MessageDigest.getInstance("MD5")
    inputStream().use { input ->
        val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
        while (true) {
            val count = input.read(buffer)
            if (count < 0) break
            digest.update(buffer, 0, count)
        }
    }
    return digest.digest().joinToString("") { byte -> "%02x".format(byte.toInt() and 0xff) }
}

val downloadDependencies by tasks.registering {
    doLast {
        val outputDirectory = layout.buildDirectory.dir("output").get().asFile
        project.delete(outputDirectory)
        outputDirectory.mkdirs()

        val filesToDownload = listOf(
            Triple(
                "https://github.com/media-kit/libmpv-android-audio-build/releases/download/v1.1.9/default-arm64-v8a.jar",
                "3057a0552b6338689fd563da4d8e2d68",
                layout.buildDirectory.file("v1.1.9/default-arm64-v8a.jar").get().asFile,
            ),
            Triple(
                "https://github.com/media-kit/libmpv-android-audio-build/releases/download/v1.1.9/default-armeabi-v7a.jar",
                "2fc445bfad52a289e1b01b8bcef3f8e0",
                layout.buildDirectory.file("v1.1.9/default-armeabi-v7a.jar").get().asFile,
            ),
            Triple(
                "https://github.com/media-kit/libmpv-android-audio-build/releases/download/v1.1.9/default-x86_64.jar",
                "b7d865cb47b70392296fe20f1a7cda68",
                layout.buildDirectory.file("v1.1.9/default-x86_64.jar").get().asFile,
            ),
            Triple(
                "https://github.com/media-kit/libmpv-android-audio-build/releases/download/v1.1.9/default-x86.jar",
                "6e8ff1aabe247021b47fc81ae3baf889",
                layout.buildDirectory.file("v1.1.9/default-x86.jar").get().asFile,
            ),
        )

        filesToDownload.forEach { (url, expectedMd5, destination) ->
            if (destination.exists() && destination.md5() != expectedMd5) {
                destination.delete()
                println("MD5 mismatch. File deleted: $destination")
            }

            if (!destination.exists()) {
                destination.parentFile.mkdirs()
                println("Downloading file from: $url")
                URI.create(url).toURL().openStream().use { input ->
                    destination.outputStream().use(input::copyTo)
                }
                if (destination.md5() != expectedMd5) {
                    throw GradleException("MD5 verification failed for $destination")
                }
            }

            project.copy {
                from(destination)
                into(outputDirectory)
            }
        }
    }
}

tasks.named("preBuild").configure {
    dependsOn(downloadDependencies)
}
