pipeline {
    agent any

    environment {
        REGISTRY = "docker.io/your-docker-user"
        APP_NAME = "quarkus-app"
        DEV_NAMESPACE = "dev"
        PROD_NAMESPACE = "prod"
        K8S_CONTEXT = "your-kube-context" // set with 'kubectl config use-context'
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/your-org/your-quarkus-app.git'
            }
        }

        stage('Build') {
            steps {
                sh './mvnw clean compile'
            }
        }

        stage('Run Tests') {
            steps {
                sh './mvnw test'
            }
        }

        stage('Package') {
            steps {
                sh './mvnw package -Dquarkus.package.type=fast-jar'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def version = sh(script: "mvn help:evaluate -Dexpression=project.version -q -DforceStdout", returnStdout: true).trim()
                    env.IMAGE_TAG = "${REGISTRY}/${APP_NAME}:${version}"
                }
                sh """
                    docker build -t $IMAGE_TAG .
                    docker push $IMAGE_TAG
                """
            }
        }

        stage('Deploy to Development') {
            steps {
                sh """
                kubectl --context=$K8S_CONTEXT -n $DEV_NAMESPACE set image deployment/${APP_NAME} ${APP_NAME}=$IMAGE_TAG --record || \
                kubectl --context=$K8S_CONTEXT -n $DEV_NAMESPACE create deployment ${APP_NAME} --image=$IMAGE_TAG
                kubectl --context=$K8S_CONTEXT -n $DEV_NAMESPACE expose deployment ${APP_NAME} --type=NodePort --port=8080 || true
                """
            }
        }

        stage('Smoke Test - Development') {
            steps {
                script {
                    // Wait for pod to be ready
                    sh "kubectl --context=$K8S_CONTEXT -n $DEV_NAMESPACE rollout status deployment/${APP_NAME} --timeout=120s"

                    // Get NodePort of the service
                    def nodePort = sh(
                        script: "kubectl --context=$K8S_CONTEXT -n $DEV_NAMESPACE get svc ${APP_NAME} -o jsonpath='{.spec.ports[0].nodePort}'",
                        returnStdout: true
                    ).trim()

                    // Assuming cluster accessible via localhost (kind/minikube) – adjust if needed
                    def appUrl = "http://localhost:${nodePort}/q/health"

                    echo "Running smoke test on ${appUrl}"
                    sh "curl -f ${appUrl}"
                }
            }
        }

        stage('Deploy to Production') {
            when {
                branch 'main'
            }
            steps {
                input message: "Deploy to Production?"
                sh """
                kubectl --context=$K8S_CONTEXT -n $PROD_NAMESPACE set image deployment/${APP_NAME} ${APP_NAME}=$IMAGE_TAG --record || \
                kubectl --context=$K8S_CONTEXT -n $PROD_NAMESPACE create deployment ${APP_NAME} --image=$IMAGE_TAG
                kubectl --context=$K8S_CONTEXT -n $PROD_NAMESPACE expose deployment ${APP_NAME} --type=LoadBalancer --port=8080 || true
                """
            }
        }
    }

    post {
        always {
            echo "Pipeline finished."
        }
    }
}
