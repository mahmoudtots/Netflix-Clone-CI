pipeline {
    agent any

    // Define required tools for the pipeline
    tools {
        nodejs 'NodeJS-18'
    }

    // Global environment variables used across stages
    environment {
        SCANNER_HOME = tool 'sonar-scanner'     // SonarScanner installation path
        TMDB_API_KEY = credentials('TMDB_API_KEY')  // TMDB API key from Jenkins credentials
        DOCKER_REGISTRY_USER = 'mahmoudtots'    // Docker registry username
        IMAGE_NAME = 'netflix-clone'            // Docker image name
    }

    stages {

        // Clean workspace and checkout source code repository
        stage('Clean & Checkout') {
            steps {
                cleanWs()
                checkout scm
            }
        }

        // Install project dependencies using Yarn
        stage('Install Dependencies') {
            steps {
                sh 'yarn install'
            }
        }

        // Run unit tests and generate coverage report
        stage('Unit Tests & Coverage') {
            steps {
                sh 'yarn test:coverage || true'
            }
        }

        // Run SonarQube static code analysis
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

        // Wait for SonarQube Quality Gate result
        stage('Quality Gate') {
            steps {
                timeout(time: 1, unit: 'HOURS') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        // Run OWASP Dependency-Check scan on filesystem
        stage('OWASP FS SCAN') {
            steps {
                withCredentials([string(credentialsId: 'NVD_API_KEY', variable: 'NVD_KEY')]) {
                    dependencyCheck additionalArguments: "--disableYarnAudit --disableNodeAudit --nvdApiKey ${NVD_KEY}",
                                    odcInstallation: 'dependency-check'
                }
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }

        // Run Trivy filesystem scan
        stage('TRIVY FS SCAN') {
            steps {
                sh "trivy fs . > trivyfs.txt"
            }
        }

        // Build Docker image and push to Docker registry
        stage("Docker Build & Push") {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', passwordVariable: 'DOCKER_PASS', usernameVariable: 'DOCKER_USER')]) {

                        // Use Jenkins build number as image tag
                        def imageTag = "${env.BUILD_NUMBER}"
                        def repoName = "${DOCKER_REGISTRY_USER}/${IMAGE_NAME}"

                        // Build Docker image with required build arguments
                        sh "docker build --build-arg VITE_APP_API_ENDPOINT_URL=https://api.themoviedb.org/3 --build-arg VITE_APP_TMDB_V3_API_KEY=${TMDB_API_KEY} -t ${repoName}:${imageTag} -t ${repoName}:latest ."

                        // Login to Docker registry and push images
                        sh "echo ${DOCKER_PASS} | docker login -u ${DOCKER_USER} --password-stdin"
                        sh "docker push ${repoName}:${imageTag}"
                        sh "docker push ${repoName}:latest"
                    }
                }
            }
        }

        // Run Trivy scan on the built Docker image
        stage("TRIVY IMAGE SCAN") {
            steps {
                sh "trivy image ${DOCKER_REGISTRY_USER}/${IMAGE_NAME}:latest > trivyimage.txt"
            }
        }

        // Build frontend artifact and upload it to Nexus repository
        stage('Build & Upload Artifacts') {
            steps {
                script {
                    sh 'yarn build'
                    sh "zip -r netflix-build-${BUILD_NUMBER}.zip dist/"

                    withCredentials([usernamePassword(credentialsId: 'nexus-creds', passwordVariable: 'NEXUS_PASS', usernameVariable: 'NEXUS_USER')]) {
                        sh """
                        curl -v -u ${NEXUS_USER}:${NEXUS_PASS} \
                        --upload-file netflix-build-${BUILD_NUMBER}.zip \
                        http://192.168.152.133:8081/repository/netflix-artifacts/netflix-build-${BUILD_NUMBER}.zip
                        """
                    }
                }
            }
        }

        // Clone CD repository and update Kubernetes deployment image tag
    //     stage('Update Deployment Image') {
    //         steps {
    //             script {

    //                 dir('cd-repo') {

    //                     checkout([
    //                         $class: 'GitSCM',
    //                         branches: [[name: '*/main']],
    //                         userRemoteConfigs: [[
    //                             url: 'https://github.com/habdelazim743-collab/complete_k8s_config_for_netfix_app.git',
    //                             credentialsId: 'git-creds'
    //                         ]]
    //                     ])

    //                     // Update image tag inside deployment.yaml
    //                     sh """
    //                     cd app
    //                     sed -i "s|image:.*|image: ${DOCKER_REGISTRY_USER}/${IMAGE_NAME}:${BUILD_NUMBER}|" deployment.yaml
    //                     """

    //                     // Commit and push updated deployment file
    //                     sh """
    //                     git config user.email "ci@company.com"
    //                     git config user.name "jenkins-ci"
    //                     git add app/deployment.yaml
    //                     git commit -m "ci: bump image tag to ${BUILD_NUMBER}" || echo "No changes"
    //                     git push origin main
    //                     """
    //                 }
    //             }
    //         }
    //     }
    // }

    // Post-build notifications
    post {
        always {
            script {
                def statusEmoji = (currentBuild.currentResult == 'SUCCESS') ? "✅" : "❌"

                def payload = """
                {
                    "project": "${env.JOB_NAME}",
                    "build_no": "${env.BUILD_NUMBER}",
                    "result": "${currentBuild.currentResult}",
                    "image": "${DOCKER_REGISTRY_USER}/${IMAGE_NAME}",
                    "emoji": "${statusEmoji}",
                    "url": "${env.BUILD_URL}",
                    "author": "Mahmoud Yousef"
                }
                """

                // Send build result to n8n webhook
                sh """
                curl -X POST -H "Content-Type: application/json" \
                -d '${payload}' \
                http://54.211.122.201:5678/webhook/ci-jenkins-alert
                """
            }

            cleanWs()
        }
    }
}
