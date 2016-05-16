def jobs = [
    [ name: 'coolstore-app-pipeline', gitUrl: 'https://github.com/sabre1041/ose-bdd-coolstore-demo.git', gitBranch: 'master', projectPath: 'projects/brms-coolstore-demo', openShiftHost: 'master.osebdd.example.com', openShiftSourceProject: 'coolstore-bdd-test', openShiftSourceApplication: 'coolstore-app', openShiftDestinationProject: 'coolstore-bdd-prod', openShiftDestinationApplication: 'coolstore-app'],
    [ name: 'coolstore-rules-pipeline', gitUrl: 'https://github.com/sabre1041/ose-bdd-coolstore-demo.git', gitBranch: 'master', projectPath: 'projects/coolstore-kjar-s2i', openShiftHost: 'master.osebdd.example.com', openShiftSourceProject: 'coolstore-bdd-test', openShiftSourceApplication: 'coolstore-rules', openShiftDestinationProject: 'coolstore-bdd-prod', openShiftDestinationApplication: 'coolstore-rules']
]

jobs.each { job ->

    workflowJob(job.name) {
		parameters {
			stringParam "OPENSHIFT_HOST",job.openShiftHost,"OpenShift Host"
			stringParam "OPENSHIFT_SOURCE_PROJECT",job.openShiftSourceProject, "OpenShift Source Project"
			stringParam "OPENSHIFT_SOURCE_APPLICATION",job.openShiftSourceApplication, "OpenShift Source Application"
			stringParam "OPENSHIFT_DESTINATION_PROJECT",job.openShiftDestinationProject, "OpenShift Destination Project"
			stringParam "OPENSHIFT_DESTINATION_APPLICATION",job.openShiftDestinationApplication, "OpenShift Destination Application"
		}

      definition {
        cpsScm {
            scm {
                git(job.gitUrl, job.gitBranch) { node -> 
                    node / 'extensions' << 'hudson.plugins.git.extensions.impl.PathRestriction' {
                      includedRegions "${job.projectPath}/.*"
                      excludedRegions ''
                    }
                    
                }
            }
            scriptPath "${job.projectPath}/Jenkinsfile"
        }    
      }
    
    }
}