pipeline {
    agent {
        label('jslave')
    }
    stages {
        stage ('Pipenv') {
            when {
                expression { env.BRANCH_NAME == 'master' }
            }
            steps {
                sh 'pipenv install --skip-lock'
            }
        }
        stage('AWS Credentials') {
            when {
                expression { env.BRANCH_NAME == 'master' }
            }
            steps {
                dir('ansible') {
                    sh './ansible.sh -s aws-credentials'
                }
            }
        }
        stage('Datadog Monitoring') {
            when {
                expression { env.BRANCH_NAME == 'master' }
            }
            steps {
                dir('ansible') {
                    sh './ansible.sh -s datadog'
                }
            }
        }
    }
}
