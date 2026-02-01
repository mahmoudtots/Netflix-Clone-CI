pipeline {
  agent any

  tools {
    nodejs 'NodeJS-18'
  }

  environment {
    SCANNER_HOME = tool 'sonar-scanner'
    TMDB_API_KEY = credentials('TMDB_API_KEY')
  }

  stages {

    stage('Clean Workspace') {
      steps {
        cleanWs()
      }
    }

    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Install Dependencies') {
      steps {
        dir('Application-Code') {
          sh 'yarn install'
        }
      }
    }

    stage('Build') {
      steps {
        dir('Application-Code') {
          sh 'yarn build'
        }
      }
    }

    stage('SonarQube Analysis') {
      steps {
        dir('Application-Code') {
          withSonarQubeEnv('sonar-server') {
            sh '''
              $SCANNER_HOME/bin/sonar-scanner \
              -Dsonar.projectName=Netflix \
              -Dsonar.projectKey=Netflix \
              -Dsonar.sources=src
            '''
          }
        }
      }
    }

    stage('Quality Gate') {
      steps {
        waitForQualityGate abortPipeline: true
      }
    }
    stage('OWASP FS SCAN') {
      steps {
       dir('Application-Code') {
        dependencyCheck additionalArguments: '--disableYarnAudit --disableNodeAudit',
                      odcInstallation: 'dependency-check'
        dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
        }
      }
    }

        stage('TRIVY FS SCAN') {
            steps {
                sh "trivy fs Application-Code > trivyfs.txt"
            }
        }
        stage("Docker Build & Push"){
            steps{
              dir('Application-Code') {
                script{
                   withDockerRegistry(credentialsId: 'mahmoudtots', toolName: 'docker'){   
                    
                       sh "docker build  --build-arg VITE_APP_API_ENDPOINT_URL=https://api.themoviedb.org/3 --build-arg VITE_APP_TMDB_V3_API_KEY=$TMDB_API_KEY -t ${DOCKER_IMAGE}:latest ."
                       sh "docker tag ${DOCKER_IMAGE} mahmoudtots/netflix:latest "
                       sh "docker push mahmoudtots/netflix:latest "
                    }
                }
              }
            }
        }
        stage("TRIVY IMAGE SCAN"){
            steps{
                sh "trivy image mahmoudtots/netflix:latest > trivyimage.txt" 
            }
        }
        stage('Deploy to container'){
            steps{
                sh '''
                  docker rm -f netflix || true
                  docker run -d --name netflix -p 8081:80 mahmoudtots/netflix:latest
                    '''

            }
        } 
  }
}
