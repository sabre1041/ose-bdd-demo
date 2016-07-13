def jobs = [
    [ name: 'coolstore-app-pipeline', gitUrl: 'http://gogs:3000/gogs/angular-brms-coolstore-demo', gitBranch: 'master', openShiftHost: 'kubernetes.default.svc.cluster.local', openShiftPort: "443", openShiftSourceProject: 'coolstore-bdd-dev', openShiftSourceApplication: 'coolstore-app', openShiftDestinationProject: 'coolstore-bdd-prod', openShiftDestinationApplication: 'coolstore-app'],
    [ name: 'coolstore-rules-pipeline', gitUrl: 'http://gogs:3000/gogs/coolstore-kjar-s2i.git', gitBranch: 'master', openShiftHost: 'kubernetes.default.svc.cluster.local', openShiftPort: "443", openShiftSourceProject: 'coolstore-bdd-dev', openShiftSourceApplication: 'coolstore-rules', openShiftDestinationProject: 'coolstore-bdd-prod', openShiftDestinationApplication: 'coolstore-rules', kieServer: 'http://coolstore-rules.coolstore-bdd-dev.svc.cluster.local:8080/kie-server/services/rest/server']
]

jobs.each { job ->

    workflowJob(job.name) {
        parameters {
            stringParam "OPENSHIFT_HOST",job.openShiftHost,"OpenShift Host"
            stringParam "OPENSHIFT_PORT",job.openShiftPort, "OpenShift Port"
            stringParam "OPENSHIFT_SOURCE_PROJECT",job.openShiftSourceProject, "OpenShift Source Project"
            stringParam "OPENSHIFT_SOURCE_APPLICATION",job.openShiftSourceApplication, "OpenShift Source Application"
            stringParam "OPENSHIFT_DESTINATION_PROJECT",job.openShiftDestinationProject, "OpenShift Destination Project"
            stringParam "OPENSHIFT_DESTINATION_APPLICATION",job.openShiftDestinationApplication, "OpenShift Destination Application"

            if(job.kieServer) {
                stringParam "KIE_SERVER_URL",job.kieServer, "KIE Server URL"
            }

        }

      definition {
        cpsScm {
            scm {
                git {
                    remote {
                        url(job.gitUrl)
                    }

                    branch(job.gitBranch) 

                }
            }
            scriptPath "Jenkinsfile"
        }    
      }
    }
}
