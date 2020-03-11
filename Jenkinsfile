@Library('auth0') _
pipeline {
  options {
  timeout(time: 25, unit: 'MINUTES') 
  }

  parameters {
  string(name: 'SlackTarget', defaultValue: '#data-monitoring', description: 'Target Slack Channel for notifications')
  }
  
  environment { // This block defines environment variables that will be available throughout the rest of the pipeline
    SERVICE_NAME = 'rauth0'
  }

  agent {
      label 'ubuntu-14'
  }

  stages {
    stage('SharedLibs') { // Required. Stage to load the Auth0 shared library for Jenkinsfile
      steps {
        library identifier: 'auth0-jenkins-pipelines-library@master', retriever: modernSCM(
        [$class: 'GitSCMSource',
        remote: 'git@github.com:auth0/auth0-jenkins-pipelines-library.git',
        credentialsId: 'auth0extensions-ssh-key'])
      }
    }

    stage('Build Docker Environment') {
      steps {
        script {
          sh """
          docker build -t ${env.BUILD_NUMBER}-${env.SERVICE_NAME} .
          """
        }
      }
    }

    stage('Test R Environment') {
      steps {
        script {
          sh """
          docker run --rm ${env.BUILD_NUMBER}-${env.SERVICE_NAME} R cmd -e 'require(rauth0)'
          """
        }
      }
    }
  }
}

post {
  cleanup {
    script {
      try {
        sh('docker rmi ${env.BUILD_NUMBER}-${env.SERVICE_NAME}')
      } catch (Exception e) {
        echo "Failed to remove docker container ${e}"
      }

      deleteDir()
    }
  }
}