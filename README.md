# Deploying  Swiggy clone app in Kubernetes Cluster using CICD Pipeline.

<div align="center">
  <img src="https://i.ytimg.com/vi/dMVrwaYojYs/hq720.jpg?sqp=-oaymwEhCK4FEIIDSFryq4qpAxMIARUAAAAAGAElAADIQj0AgKJD&rs=AOn4CLDFY-RWFRoPVJ8Cl1R4nXXC4ay1Ng" alt="Logo" width="90%" height="90%">
  <p align="center"</p>
</div>


### Pipeline Script

pipeline {
    agent any
    
    tools {
        jdk 'jdk17'
        nodejs 'node16'
    }
    
    environment {
        SCANNER_HOME = tool 'sonarqube-scanner'
    }
    
    stages {
        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }
        
        stage('Checkout from Git') {
            steps {
                git branch: 'main', url: 'https://github.com/username/a-swiggy-clone.git'
            }
        }
        
        stage("Sonarqube Analysis ") {
            steps {
                withSonarQubeEnv('SonarQube-Server') {
                    sh ''' 
                    $SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=Swiggy-CI \
                    -Dsonar.projectKey=Swiggy-CI 
                    '''
                }
            }
        }
        
        stage("Quality Gate") {
            steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'SonarQube-Token' 
                }
            } 
        }
        
        stage('Install Dependencies') {
            steps {
                sh "npm install"
            }
        }
        
        stage('TRIVY FS SCAN') {
            steps {
                sh "trivy fs . > trivyfs.txt"
            }
        }
        
        stage("Docker Build & Push") {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'dockerhub', toolName: 'docker') {   
                        sh "docker build -t swiggy-clone ."
                        sh "docker tag swiggy-clone username/swiggy-clone:latest "
                        sh "docker push username/swiggy-clone:latest "
                    }
                }
            }
        }
        
        stage("TRIVY") {
            steps {
                sh "trivy image username/swiggy-clone:latest > trivyimage.txt" 
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    dir('Kubernetes') {
                        kubeconfig(credentialsId: 'kubernetes', serverUrl: '') {
                            sh 'kubectl delete --all pods'
                            sh 'kubectl apply -f deployment.yml'
                            sh 'kubectl apply -f service.yml'
                        }   
                    }
                }
            }
        }
    }
}


