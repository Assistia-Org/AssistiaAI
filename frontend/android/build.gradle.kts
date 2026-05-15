allprojects {
    repositories {
        google()
        mavenCentral()
    }
    configurations.all {
        resolutionStrategy {
            force("org.jetbrains.kotlin:kotlin-stdlib:2.1.10")
            force("org.jetbrains.kotlin:kotlin-stdlib-jdk7:2.1.10")
            force("org.jetbrains.kotlin:kotlin-stdlib-jdk8:2.1.10")
            force("org.jetbrains.kotlin:kotlin-stdlib-common:2.1.10")
            
            // Force stable AndroidX versions to avoid AGP 8.9.1 requirement
            force("androidx.core:core:1.13.1")
            force("androidx.core:core-ktx:1.13.1")
            force("androidx.activity:activity:1.9.1")
            force("androidx.activity:activity-ktx:1.9.1")
            force("androidx.browser:browser:1.8.0")
            
            // Force 4.0.0 which has the required Heatmap updateData method
            force("com.google.maps.android:android-maps-utils:4.0.0")
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
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
