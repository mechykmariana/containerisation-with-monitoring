pipeline {
  agent any

  parameters {
    booleanParam(
      name: 'RECREATE_INFRA',
      defaultValue: false,
      description: 'Destroy and recreate infrastructure before apply'
    )
  }

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

    stage('Terraform Destroy') {
      when {
        expression { return params.RECREATE_INFRA == true }
      }
      steps {
        dir('terraform/aws') {
          withAWS(credentials: 'aws-credentials', region: "${env.AWS_REGION}") {
            withCredentials([
              string(credentialsId: 'ec2-pub-key', variable: 'PUB_KEY'),
              sshUserPrivateKey(credentialsId: 'ssh-key', keyFileVariable: 'SSH_KEY')
            ]) {
              writeFile file: 'id_rsa_terraform.pub', text: env.PUB_KEY
              sh 'terraform destroy -auto-approve -var "private_key_path=$SSH_KEY" || true'
            }
          }
        }
      }
    }

    stage('Terraform Init & Plan') {
      steps {
        dir('terraform/aws') {
          withAWS(credentials: 'aws-credentials', region: "${env.AWS_REGION}") {
            withCredentials([string(credentialsId: 'ec2-pub-key', variable: 'PUB_KEY')]) {
              writeFile file: 'id_rsa_terraform.pub', text: env.PUB_KEY
            }
            sh 'terraform init'
            sh 'terraform plan'
          }
        }
      }
    }

    stage('Terraform Apply') {
      steps {
        dir('terraform/aws') {
          withAWS(credentials: 'aws-credentials', region: "${env.AWS_REGION}") {
            withCredentials([
              string(credentialsId: 'ec2-pub-key', variable: 'PUB_KEY'),
              sshUserPrivateKey(credentialsId: 'ssh-key', keyFileVariable: 'SSH_KEY')
            ]) {
              writeFile file: 'id_rsa_terraform.pub', text: env.PUB_KEY
              sh '''
                echo "Private key path: $SSH_KEY"
                ls -la $SSH_KEY
                head -2 $SSH_KEY
              '''
              sh 'terraform apply -auto-approve -var "private_key_path=$SSH_KEY"'
            }
          }
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
