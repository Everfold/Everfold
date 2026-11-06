allprojects {
    // Flutter plugins such as share_plus resolve AGP in their own buildscript.
    // Configure this before their scripts add google(), so the mirror is tried first.
    buildscript {
        repositories {
            maven("https://maven.aliyun.com/repository/google")
        }
    }

    repositories {
        maven("https://maven.aliyun.com/repository/google")
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
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
