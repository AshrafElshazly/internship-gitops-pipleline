pipeline {
    agent any

    tools {
        maven 'Maven 3'
    }

    environment {
        DOCKER_REPO = 'ashrafelshazlii/java-app-test'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build') {
            steps {
                sh 'mvn clean install -DskipTests'
                sh '''
                    JAR_NAME=$(ls target/*.jar | grep -v 'original' | head -n 1)
                    cp "$JAR_NAME" target/app.jar
                '''
            }
        }

        stage('Unit Test') {
            steps {
                sh 'mvn test'
                junit 'target/surefire-reports/**/*.xml'
            }
        }

        stage('Build and Push Docker Image') {
            steps {
                script {
                    withCredentials([
                        usernamePassword(
                            credentialsId: 'DockerHubCreds',
                            usernameVariable: 'DOCKER_USERNAME',
                            passwordVariable: 'DOCKER_PASSWORD'
                        )
                    ]) {
                        def version = sh(
                            script: "mvn help:evaluate -Dexpression=project.version -q -DforceStdout",
                            returnStdout: true
                        ).trim()

                        env.APP_VERSION = version
                        def image = "${DOCKER_REPO}:${version}"
                        def imageLatest = "${DOCKER_REPO}:latest"

                        sh """
                            echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_USERNAME}" --password-stdin
                            docker build -t ${image} -t ${imageLatest} .
                            docker push ${image}
                            docker push ${imageLatest}
                        """
                    }
                }
            }
        }

        stage('Update Manifests') {
            steps {
                script {
                    withCredentials([
                        usernamePassword(
                            credentialsId: 'GitHubCreds',
                            usernameVariable: 'GIT_USER',
                            passwordVariable: 'GIT_TOKEN'
                        )
                    ]){
                        def branch = env.GIT_BRANCH.replaceFirst(/^origin\//, '')
                        def overlayPath = (branch == 'main') ? 'overlays/prod' : "overlays/${branch}"

                        sh """
                            git config --global user.email "ci@jenkins.local"
                            git config --global user.name "${GIT_USER}"

                            rm -rf internship-gitops-manifests
                            git clone https://${GIT_USER}:${GIT_TOKEN}@github.com/ashrafelshazly/internship-gitops-manifests.git
                            cd internship-gitops-manifests/${overlayPath}

                            kustomize edit set image ${DOCKER_REPO}:${APP_VERSION}

                            git add .
                            git commit -m "Update image to ${APP_VERSION} in ${overlayPath} via Jenkins"
                            git push origin ${branch}
                        """
                    }
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline completed!'
        }
    }
}
