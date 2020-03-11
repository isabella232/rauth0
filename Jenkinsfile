pipeline {
    agent { dockerfile true }
    stages {

        stage('Test R Environment') {
            steps {
                R -e require(rauth0)
            }
        }
    }
}