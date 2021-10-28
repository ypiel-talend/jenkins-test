def branchName = env.BRANCH_NAME

pipeline {
    agent { docker { image 'maven:3.3.3' } }
    stages {
        stage('build') {
            steps {
		CREATE_BRANCH_OUT = sh (
					script: '.Jenkins/create-branch.sh',
					returnStdout: true
		).trim()
		echo "Create branch: ${CREATE_BRANCH_OUT}"
            }
        }
    }
}

