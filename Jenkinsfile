pipeline {
    agent any

    environment {
        DOCKER_HUB_CREDS = credentials('docker-hub-credentials')
        GIT_REPO_URL = 'https://github.com/bansalsahab/Arcon.git'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Images') {
            steps {
                script {
                    docker.build("bansalsahab/arcon-backend:${IMAGE_TAG}", "-f backend/Dockerfile backend")
                    docker.build("bansalsahab/arcon-frontend:${IMAGE_TAG}", "-f frontend/Dockerfile frontend")
                }
            }
        }

        stage('Push to Registry') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', 'docker-hub-credentials') {
                        docker.image("bansalsahab/arcon-backend:${IMAGE_TAG}").push()
                        docker.image("bansalsahab/arcon-backend:${IMAGE_TAG}").push("latest")
                        docker.image("bansalsahab/arcon-frontend:${IMAGE_TAG}").push()
                        docker.image("bansalsahab/arcon-frontend:${IMAGE_TAG}").push("latest")
                    }
                }
            }
        }

        stage('Update K8s Manifests') {
            steps {
                script {
                    // GitOps pattern: Update the image tag in the deployment files
                    sh "sed -i 's|bansalsahab/arcon-backend:.*|bansalsahab/arcon-backend:${IMAGE_TAG}|' k8s/backend-deployment.yaml"
                    sh "sed -i 's|bansalsahab/arcon-frontend:.*|bansalsahab/arcon-frontend:${IMAGE_TAG}|' k8s/frontend-deployment.yaml"
                    
                    // Commit changes back to repo
                    withCredentials([usernamePassword(credentialsId: 'github-token', usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD')]) {
                        sh '''
                            git config user.email "jenkins@arcon.com"
                            git config user.name "Jenkins Bot"
                            git add k8s/*.yaml
                            git commit -m "Update image tag to ${IMAGE_TAG} [skip ci]"
                            git push https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/bansalsahab/Arcon.git HEAD:main
                        '''
                    }
                }
            }
        }
    }
}
