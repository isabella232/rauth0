@Library('auth0') _
pipeline {
	options {
		timeout(time: 15, unit: 'MINUTES') // Global timeout for the job. Recommended to make the job fail if it's taking too long
	}

	parameters { // Job parameters that need to be supplied when the job is run. If they have a default value they won't be required
		string(name: 'SlackTarget', defaultValue: '#data-monitoring', description: 'Target Slack Channel for notifications')
	}
 
	agent {
	    dockerfile {
	        filename 'Dockerfile'
	        label 'rauth0'
	    }
	}
    stages {

        stage('Test R Environment') {
            steps {
                sh 'R -e "require(rauth0)"'
            }
        }
    }
}

post {
    cleanup {
        script {
            try {
                sh('docker rmi rauth0')
            } catch (Exception e) {
                echo "Failed to remove docker container ${e}"
            }

            deleteDir()
        }
    }
}