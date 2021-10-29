def branchName = env.BRANCH_NAME

pipeline {
    agent { docker { image 'maven:3.3.3' } }
    parameters {
        booleanParam(name: 'DRY_RUN', defaultValue: false, description: 'DRY_RUN mode')
        booleanParam(name: 'DEBUG', defaultValue: false, description: 'DEBUG mode')
    }
    environment {
        DRY_RUN="${params.DRY_RUN}"
        DEBUG="${params.DEBUG}"
    }
    stages {
        stage('build') {
            steps {
		script{
			CREATE_BRANCH_OUT = sh (
						script: '.Jenkins/create-branch.sh',
						returnStdout: true
			).trim()
			echo "Create branch: ${CREATE_BRANCH_OUT}"
		}
            }
	    step {
		input{
			message "Could you check PR ?"
		}
            }
        }
    }
}

