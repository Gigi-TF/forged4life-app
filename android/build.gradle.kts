allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    /*
     * Force every plugin up to compileSdk 36.
     *
     * Some plugins pin themselves to an older SDK — file_picker sits on 34 —
     * and the build fails the moment anything else in the tree needs 36. We
     * cannot edit those packages, so we raise them here.
     *
     * Safe: compileSdk only decides which APIs are available at compile time.
     * It does not change runtime behaviour (targetSdk) or which devices can
     * install the app (minSdk).
     *
     * This MUST be registered before the evaluationDependsOn block below —
     * that line forces subprojects to evaluate, and afterEvaluate cannot be
     * added to a project that has already been evaluated.
     *
     * Remove once file_picker is upgraded and no plugin lags behind.
     */
    afterEvaluate {
        extensions.findByName("android")?.let { android ->
            runCatching {
                android.javaClass
                    .getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType)
                    .invoke(android, 36)
            }.onFailure {
                logger.warn("compileSdk not raised for ${project.name}: ${it.message}")
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}