pipeline {
    agent { label 'debian-arm64'}

    stages {
        stage('Build') {
            steps {
                sh '/bin/bash ./validate.sh'
            }
        }
    }
}
