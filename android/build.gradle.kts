allprojects {
    repositories {
        google()
        mavenCentral()
    }
    id("org.jlleitschuh.gradle.ktlint") version "11.6.0"
    id("io.gitlab.arturbosch.detekt") version "1.23.0"
}

buildscript {
    repositories {
        mavenCentral()
    }
}

apply(plugin = "org.jlleitschuh.gradle.ktlint")
apply(plugin = "io.gitlab.arturbosch.detekt")

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
