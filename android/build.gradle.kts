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
}

subprojects {
    project.evaluationDependsOn(":app")
    
    configurations.all {
        resolutionStrategy {
            // Force stable versions of Glance to avoid the AGP 9.1.0 requirement
            force("androidx.glance:glance:1.1.0")
            force("androidx.glance:glance-appwidget:1.1.0")
            force("androidx.glance:glance-material3:1.1.0")
            
            // Force a lower version of remote-creation or let it be resolved by glance 1.1.0
            force("androidx.compose.remote:remote-creation-android:1.0.0-alpha01")
            
            // Ensure WorkManager consistency
            force("androidx.work:work-runtime:2.8.1")
            force("androidx.work:work-runtime-ktx:2.8.1")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
