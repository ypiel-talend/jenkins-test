def branchName = env.BRANCH_NAME
def branchNameX = getCurrentBranch()

pipeline {
    agent { docker { image 'maven:3.3.3' } }
    stages {
        stage('build') {
            steps {
                sh 'mvn --version'
		sh 'echo "------------------------------------"'
		sh 'git --version'
		sh 'echo "branch is: ${branchName}"'
		println("The branch is: " + branchName)
		println("The branch is XX : " + branchNameX)
		sh '.Jenkins/create-branch.sh'
            }
        }
    }
}

