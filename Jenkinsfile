pipeline {
    agent any

    tools {
        nodejs 'NodeJS-18'
    }

    environment {
        SCANNER_HOME = tool 'sonar-scanner'
        TMDB_API_KEY = credentials('TMDB_API_KEY')
        DOCKER_REGISTRY_USER = 'mahmoudtots'
    }

    stages {
        stage('Clean & Checkout') {
            steps {
                cleanWs()
                checkout scm
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'yarn install'
            }
        }

        stage('Unit Tests & Coverage') {
            steps {
                sh 'yarn test:coverage || true'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonar-server') {
                    sh """
                    $SCANNER_HOME/bin/sonar-scanner \
                    -Dsonar.projectName=Netflix \
                    -Dsonar.projectKey=Netflix \
                    -Dsonar.sources=src \
                    -Dsonar.tests=src \
                    -Dsonar.test.inclusions='**/*.test.tsx,**/*.spec.tsx' \
                    -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info
                    """
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 1, unit: 'HOURS') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('OWASP FS SCAN') {
            steps {
              withCredentials([string(credentialsId: 'NVD_API_KEY', variable: 'NVD_KEY')]) {
                dependencyCheck additionalArguments: "--disableYarnAudit --disableNodeAudit --nvdApiKey ${NVD_KEY}",
                                odcInstallation: 'dependency-check'
              }
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
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
                    // استخدام الكريدنشالز مباشرة بدل تول الدوكر
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', passwordVariable: 'DOCKER_PASS', usernameVariable: 'DOCKER_USER')]) {
                        
                        // بناء الصورة مع تمرير الـ API Key كـ Build Arg
                        sh "docker build --build-arg VITE_APP_TMDB_V3_API_KEY=${TMDB_API_KEY} -t ${DOCKER_REGISTRY_USER}/netflix:latest ."
                        
                        // تسجيل الدخول والرفع
                        sh "echo ${DOCKER_PASS} | docker login -u ${DOCKER_USER} --password-stdin"
                        sh "docker push ${DOCKER_REGISTRY_USER}/netflix:latest"
                    }
                }
            }
        }

        stage("TRIVY IMAGE SCAN") {
            steps {
                sh "trivy image ${DOCKER_REGISTRY_USER}/netflix:latest > trivyimage.txt" 
            }
        }

        stage('Deploy to Container') {
            steps {
                sh '''
                docker rm -f netflix || true
                docker run -d --name netflix -p 8081:80 mahmoudtots/netflix:latest
                '''
            }
        } 
    }
}