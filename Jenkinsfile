pipeline {
  agent any

  environment {
    FRONTEND_IMAGE = "marianamechyk/react-frontend:latest"
    BACKEND_IMAGE  = "marianamechyk/django-backend:latest"
  }

  stages {
    stage('Build Frontend Image') {
      steps {
        dir('ComputexFrontend') {
          sh "docker build -t $FRONTEND_IMAGE ."
        }
      }
    }

    stage('Build Backend Image') {
      steps {
        dir('Computex') {
          sh "docker build -t $BACKEND_IMAGE ."
        }
      }
    }

    stage('Push Images to DockerHub') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          sh """
            echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
            docker push $FRONTEND_IMAGE
            docker push $BACKEND_IMAGE
          """
        }
      }
    }

    stage('Terraform Init & Apply') {
      steps {
        dir('terraform/aws') {
          sh 'terraform init'
          sh 'terraform plan'
          sh 'terraform apply -auto-approve'
        }
      }
    }
  }

  post {
    failure {
      echo 'Deployment failed.'
    }
    success {
      echo 'Deployment successful!'
    }
  }
}
