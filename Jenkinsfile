def branchName = env.BRANCH_NAME

pipeline {
    agent { docker { image 'maven:3.3.3' } }
    stages {
        stage('build') {
            steps {
		sh '.Jenkins/create-branch.sh'
            }
        }
    }
}

