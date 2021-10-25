def branchName = env.BRANCH_NAME

pipeline {
    agent { docker { image 'maven:3.3.3' } }
    stages {
        stage('build') {
            steps {
                sh 'mvn --version'
		sh 'echo "------------------------------------"'
		sh 'git --version'
		sh 'echo "branch is: ${branchName}'
		println("The branch is: " + branchName)
		sh '.Jenkins/create-branch.sh'
            }
        }
    }
}

