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
    afterEvaluate {
        val android = extensions.findByName("android") ?: return@afterEvaluate
        val setCompileSdk = android.javaClass.methods.firstOrNull {
            it.name == "setCompileSdkVersion" && it.parameterCount == 1 && it.parameterTypes[0] == Int::class.java
        } ?: return@afterEvaluate
        setCompileSdk.invoke(android, 36)
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
