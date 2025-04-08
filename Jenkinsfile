// pipeline {
//   agent any

//   parameters {
//     booleanParam(
//       name: 'RECREATE_INFRA',
//       defaultValue: false,
//       description: 'Destroy and recreate infrastructure before apply'
//     )
//   }

//   environment {
//     FRONTEND_IMAGE = "marianamechyk/react-frontend:latest"
//     BACKEND_IMAGE  = "marianamechyk/django-backend:latest"
//   }

//   stages {

//     // stage('Clean Terraform State (AWS)') {
//     //   when {
//     //     expression { return params.RECREATE_INFRA == true }
//     //   }
//     //   steps {
//     //     dir('terraform/aws') {
//     //       echo "Removing previous terraform state..."
//     //       sh 'rm -rf .terraform terraform.tfstate terraform.tfstate.backup || true'
//     //     }
//     //   }
//     // }

//     stage('Clean Terraform State (Azure)') {
//       when {
//         expression { return params.RECREATE_INFRA == true }
//       }
//       steps {
//         dir('terraform/azure') {
//           echo "Removing previous terraform state..."
//           sh 'rm -rf .terraform terraform.tfstate terraform.tfstate.backup || true'
//         }
//       }
//     }

//     stage('Build Frontend Image') {
//       steps {
//         dir('ComputexFrontend') {
//           echo "Building frontend image without cache..."
//           sh "docker build --no-cache -t $FRONTEND_IMAGE ."
//         }
//       }
//     }

//     stage('Build Backend Image') {
//       steps {
//         dir('Computex') {
//           echo "Building backend image without cache..."
//           sh "docker build --no-cache -t $BACKEND_IMAGE ."
//         }
//       }
//     }

//     stage('Push Images to DockerHub') {
//       steps {
//         withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
//           sh """
//             echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
//             docker push $FRONTEND_IMAGE
//             docker push $BACKEND_IMAGE
//           """
//         }
//       }
//     }

//     // stage('Terraform Destroy (AWS)') {
//     //   when {
//     //     expression { return params.RECREATE_INFRA == true }
//     //   }
//     //   steps {
//     //     dir('terraform/aws') {
//     //       withAWS(credentials: 'aws-credentials', region: "${env.AWS_REGION}") {
//     //         withCredentials([
//     //           string(credentialsId: 'ec2-pub-key', variable: 'PUB_KEY'),
//     //           sshUserPrivateKey(credentialsId: 'ssh-key', keyFileVariable: 'SSH_KEY')
//     //         ]) {
//     //           writeFile file: 'id_rsa_terraform.pub', text: env.PUB_KEY
//     //           sh 'terraform destroy -auto-approve -var "private_key_path=$SSH_KEY" || true'
//     //         }
//     //       }
//     //     }
//     //   }
//     // }

//     stage('Terraform Destroy (Azure)') {
//       when {
//         expression { return params.RECREATE_INFRA == true }
//       }
//       steps {
//         dir('terraform/azure') {
//           withAWS(credentials: 'aws-credentials', region: "${env.AWS_REGION}") {
//             withCredentials([
//               string(credentialsId: 'ec2-pub-key', variable: 'PUB_KEY'),
//               sshUserPrivateKey(credentialsId: 'ssh-key', keyFileVariable: 'SSH_KEY')
//             ]) {
//               writeFile file: 'id_rsa_terraform.pub', text: env.PUB_KEY
//               sh 'terraform destroy -auto-approve -var "private_key_path=$SSH_KEY" || true'
//             }
//           }
//         }
//       }
//     }

//     // stage('Terraform Init & Apply (AWS)') {
//     //   steps {
//     //     dir('terraform/aws') {
//     //       withAWS(credentials: 'aws-credentials', region: "${env.AWS_REGION}") {
//     //         withCredentials([
//     //           string(credentialsId: 'ec2-pub-key', variable: 'PUB_KEY'),
//     //           sshUserPrivateKey(credentialsId: 'ssh-key', keyFileVariable: 'SSH_KEY')
//     //         ]) {
//     //           writeFile file: 'id_rsa_terraform.pub', text: env.PUB_KEY
//     //           sh 'terraform init'
//     //           sh 'terraform apply -auto-approve -var "private_key_path=$SSH_KEY"'
//     //         }
//     //       }
//     //     }
//     //   }
//     // }
//   }

//   post {
//     failure {
//       echo 'Deployment failed.'
//     }
//     success {
//       echo 'Deployment completed successfully!'
//     }
//   }
// }



pipeline {
  agent any

  parameters {
    choice(
      name: 'CLOUD_PROVIDER',
      choices: ['aws', 'azure'],
      description: 'Select cloud provider for deployment'
    )
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

    stage('Clean Terraform State') {
      when {
        expression { return params.RECREATE_INFRA == true }
      }
      steps {
        script {
          def tfDir = "terraform/${params.CLOUD_PROVIDER}"
          dir(tfDir) {
            sh 'rm -rf .terraform terraform.tfstate terraform.tfstate.backup || true'
          }
        }
      }
    }

    stage('Build Frontend Image') {
      steps {
        dir('ComputexFrontend') {
          sh "docker build --no-cache -t $FRONTEND_IMAGE ."
        }
      }
    }

    stage('Build Backend Image') {
      steps {
        dir('Computex') {
          sh "docker build --no-cache -t $BACKEND_IMAGE ."
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
        script {
          def tfDir = "terraform/${params.CLOUD_PROVIDER}"
          dir(tfDir) {
            if (params.CLOUD_PROVIDER == 'aws') {
              withAWS(credentials: 'aws-credentials', region: "${env.AWS_REGION}") {
                withCredentials([
                  string(credentialsId: 'ec2-pub-key', variable: 'PUB_KEY'),
                  sshUserPrivateKey(credentialsId: 'ssh-key', keyFileVariable: 'SSH_KEY')
                ]) {
                  writeFile file: 'id_rsa_terraform.pub', text: env.PUB_KEY
                  sh 'terraform destroy -auto-approve -var "private_key_path=$SSH_KEY"'
                }
              }
            } else if (params.CLOUD_PROVIDER == 'azure') {
              withCredentials([
                sshUserPrivateKey(credentialsId: 'azure-ssh-key',
                keyFileVariable: 'SSH_KEY_FILE',
                passphraseVariable: 'SSH_PASSPHRASE',
                usernameVariable: 'SSH_USERNAME'),
                string(credentialsId: 'azure-pub-key', variable: 'PUB_KEY'),
                azureServicePrincipal(credentialsId: 'azure-creds', subscriptionIdVariable: 'AZ_SUBSCRIPTION_ID', clientIdVariable: 'AZ_CLIENT_ID', clientSecretVariable: 'AZ_CLIENT_SECRET', tenantIdVariable: 'AZ_TENANT_ID')
              ]) {
                writeFile file: 'id_rsa_azure.pub', text: readFile(env.PUB_KEY)
                sh '''
                  export ARM_SUBSCRIPTION_ID=$AZ_SUBSCRIPTION_ID
                  export ARM_CLIENT_ID=$AZ_CLIENT_ID
                  export ARM_CLIENT_SECRET=$AZ_CLIENT_SECRET
                  export ARM_TENANT_ID=$AZ_TENANT_ID
                  terraform destroy -auto-approve -var "ssh_public_key=id_rsa_azure.pub" -var "private_key_path=$SSH_KEY_FILE"
                '''
              }
            }
          }
        }
      }
    }

    stage('Terraform Init & Apply') {
      steps {
        script {
          def tfDir = "terraform/${params.CLOUD_PROVIDER}"
          dir(tfDir) {
            if (params.CLOUD_PROVIDER == 'aws') {
              withAWS(credentials: 'aws-credentials', region: "${env.AWS_REGION}") {
                withCredentials([
                  string(credentialsId: 'ec2-pub-key', variable: 'PUB_KEY'),
                  sshUserPrivateKey(credentialsId: 'ssh-key', keyFileVariable: 'SSH_KEY')
                ]) {
                  writeFile file: 'id_rsa_terraform.pub', text: env.PUB_KEY
                  sh 'terraform init'
                  sh 'terraform apply -auto-approve -var "private_key_path=$SSH_KEY"'
                }
              }
            } else if (params.CLOUD_PROVIDER == 'azure') {
              withCredentials([
                file(credentialsId: 'azure-ssh-key', variable: 'SSH_KEY'),
                file(credentialsId: 'azure-pub-key', variable: 'PUB_KEY'),
                azureServicePrincipal(credentialsId: 'azure-credentials', subscriptionIdVariable: 'AZ_SUBSCRIPTION_ID', clientIdVariable: 'AZ_CLIENT_ID', clientSecretVariable: 'AZ_CLIENT_SECRET', tenantIdVariable: 'AZ_TENANT_ID')
              ]) {
                writeFile file: 'id_rsa_azure.pub', text: readFile(env.PUB_KEY)
                sh '''
                  export ARM_SUBSCRIPTION_ID=$AZ_SUBSCRIPTION_ID
                  export ARM_CLIENT_ID=$AZ_CLIENT_ID
                  export ARM_CLIENT_SECRET=$AZ_CLIENT_SECRET
                  export ARM_TENANT_ID=$AZ_TENANT_ID
                  terraform init
                  terraform apply -auto-approve -var "ssh_public_key=id_rsa_azure.pub" -var "private_key_path=$SSH_KEY"
                '''
              }
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
      echo "${params.CLOUD_PROVIDER.toUpperCase()} Deployment completed successfully!"
    }
  }
}
