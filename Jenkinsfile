@Library('auth0') _
pipeline {
	agent {
	    dockerfile {
	        filename 'Dockerfile'
	        label 'rauth0'
	    }
	}
    stages {

        stage('Test R Environment') {
            steps {
                R -e require(rauth0)
            }
        }
    }
}

post {
  cleanup {
    script {
      try {
        sh('docker rmi -f $(docker images | grep rauth0 | tr -s ' ' | cut -d ' ' -f 3)')
      } catch (Exception e) {
        echo "Failed to remove docker container ${e}"
      }
    }
  }
}