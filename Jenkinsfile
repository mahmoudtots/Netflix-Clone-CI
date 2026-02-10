pipeline {
    agent any
   // تعريف الأدوات المستخدمة في البايبلاين
    tools {
        nodejs 'NodeJS-18'
    }
    // تعريف المتغيرات البيئية
   environment {
       SCANNER_HOME = tool 'sonar-scanner'
       TMDB_API_KEY = credentials('TMDB_API_KEY')
       DOCKER_REGISTRY_USER = 'mahmoudtots'
       IMAGE_NAME = 'netflix-clone'
   }
   // مراحل البايبلاين
   // استدعاء الكود من المستودع وتنظيف مساحة العمل
     stages {
        stage('Clean & Checkout') {
            steps {
                cleanWs()
                checkout scm
            }
        }
    // تثبيت التبعيات
        stage('Install Dependencies') {
            steps {
                sh 'yarn install'
            }
        }
    // اختبارات الوحدة والتغطية
        // stage('Unit Tests & Coverage') {
        //     steps {
        //         sh 'yarn test:coverage || true'
        //     }
        // }
    // تحليل SonarQube
        // stage('SonarQube Analysis') {
        //     steps {
        //         withSonarQubeEnv('sonar-server') {
        //             sh """
        //             $SCANNER_HOME/bin/sonar-scanner \
        //             -Dsonar.projectName=Netflix \
        //             -Dsonar.projectKey=Netflix \
        //             -Dsonar.sources=src \
        //             -Dsonar.tests=src \
        //             -Dsonar.test.inclusions='**/*.test.tsx,**/*.spec.tsx' \
        //             -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info
        //             """
        //         }
        //     }
        // }
    // بوابة الجودة
        // stage('Quality Gate') {
        //     steps {
        //         timeout(time: 1, unit: 'HOURS') {
        //             waitForQualityGate abortPipeline: true
        //         }
        //     }
        // }
    // مسح نظام الملفات باستخدام OWASP Dependency-Check
        // stage('OWASP FS SCAN') {
        //     steps {
        //       withCredentials([string(credentialsId: 'NVD_API_KEY', variable: 'NVD_KEY')]) {
        //         dependencyCheck additionalArguments: "--disableYarnAudit --disableNodeAudit --nvdApiKey ${NVD_KEY}",
        //                         odcInstallation: 'dependency-check'
        //       }
        //         dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
        //     }
        // }
    // مسح نظام الملفات باستخدام Trivy
        // stage('TRIVY FS SCAN') {
        //     steps {
        //         sh "trivy fs . > trivyfs.txt"
        //     }
        // }
    // بناء ورفع صورة الدوكر
        stage("Docker Build & Push") {
            steps {
                script {
                    // استخدام الكريدنشالز مباشرة بدل تول الدوكر
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', passwordVariable: 'DOCKER_PASS', usernameVariable: 'DOCKER_USER')]) {
                        // تعريف متغير للتاج باستخدام رقم البلد
                        def imageTag = "${env.BUILD_NUMBER}"
                        def repoName = "${DOCKER_REGISTRY_USER}/${IMAGE_NAME}"
                        // بناء الصورة مع تمرير الـ API Key كـ Build Arg
                        sh "docker build --build-arg VITE_APP_API_ENDPOINT_URL=https://api.themoviedb.org/3 --build-arg VITE_APP_TMDB_V3_API_KEY=${TMDB_API_KEY} -t ${repoName}:${imageTag} -t ${repoName}:latest ."
                        
                        // تسجيل الدخول والرفع
                        sh "echo ${DOCKER_PASS} | docker login -u ${DOCKER_USER} --password-stdin"
                        sh "docker push ${repoName}:${imageTag}"
                        sh "docker push ${repoName}:latest"
                    }
                }
            }
        }
    // مسح الصور باستخدام Trivy
        // stage("TRIVY IMAGE SCAN") {
        //     steps {
        //         sh "trivy image ${DOCKER_REGISTRY_USER}/${IMAGE_NAME}:latest > trivyimage.txt" 
        //     }
        // }
        // stage('Build & Upload Artifacts') {
        //     steps {
        //         script {
        //             // 1. بناء المشروع
        //             sh 'yarn build'
                    
        //             // 2. ضغط مجلد التوزيع
        //             sh "zip -r netflix-build-${BUILD_NUMBER}.zip dist/"

        //             // 3. الرفع إلى نكسس (Raw Repository)
        //             withCredentials([usernamePassword(credentialsId: 'nexus-creds', passwordVariable: 'NEXUS_PASS', usernameVariable: 'NEXUS_USER')]) {
        //                 sh """
        //                 curl -v -u ${NEXUS_USER}:${NEXUS_PASS} \
        //                 --upload-file netflix-build-${BUILD_NUMBER}.zip \
        //                 http://192.168.152.133:8081/repository/netflix-artifacts/netflix-build-${BUILD_NUMBER}.zip
        //                 """
        //             }
        //         }
        //     }
        // }
    // نشر الحاوية
        stage('Deploy to Container') {
            steps {
                sh "docker rm -f ${IMAGE_NAME} || true"
                sh "docker run -d --name ${IMAGE_NAME} -p 8085:5000 ${DOCKER_REGISTRY_USER}/${IMAGE_NAME}:${env.BUILD_NUMBER}"
            }
        }
          } 
    // Notifications with email and Slack
       post {
        always {
            script {
                // 1. تحديد الرموز التعبيرية بناءً على النتيجة
                def statusEmoji = (currentBuild.currentResult == 'SUCCESS') ? "✅" : "❌"
                
                // 2. تجهيز البيانات (Payload)
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
                
                // 3. إرسال البيانات لـ n8n (استخدم الـ Test URL في البداية)
                sh """
                curl -X POST -H "Content-Type: application/json" \
                -d '${payload}' \
                http://54.211.122.201:5678/webhook/ci-jenkins-alert
                """
            }
            // تنظيف مساحة العمل
            cleanWs()
        }
        // success {
        //     mail to: 'mahmoudyousef055@gmail.com',
        //          subject: "Success: Pipeline ${currentBuild.fullDisplayName}",
        //          body: "Great job! The Netflix Clone pipeline finished successfully. Check it here: ${env.BUILD_URL}"
        //     // slackSend channel: '#ci',
        //     //          color: 'good',
        //     //           message: "${statusEmoji}${statusEmoji}${statusEmoji} The build was successful: ${env.JOB_NAME} [${env.BUILD_NUMBER}] Check it here: ${env.BUILD_URL}"
        // }
        // failure {
        //     mail to: 'mahmoudyousef055@gmail.com',
        //          subject: "Failed: Pipeline ${currentBuild.fullDisplayName}",
        //          body: "Something went wrong! The Netflix Clone pipeline failed. Review the logs here: ${env.BUILD_URL}"
        // //     slackSend channel: '#ci',
        // //               color: 'danger',
        // //              message: "${statusEmoji}${statusEmoji}${statusEmoji}The build failed: ${env.JOB_NAME} [${env.BUILD_NUMBER}] Review the logs here: ${env.BUILD_URL}"
        // }
    }
}
