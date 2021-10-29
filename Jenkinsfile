def branchName = env.BRANCH_NAME

pipeline {
    agent { docker { image 'maven:3.3.3' } }
    parameters {
        string(name: 'SHELL_CMD', defaultValue: "", description: 'Execute a shell command at the beginning.')
    }
    stages {
	stage('init') {
		steps {
			script{
			    if (params.POST_LOGIN_SCRIPT?.trim()) {
				params.POST_LOGIN_SCRIPT = params.POST_LOGIN_SCRIPT.trim() + ' &&'
			    }
			}
		}
	}
        stage('build') {
            steps {
		script{
			CREATE_BRANCH_OUT = sh (
						script: '${params.POST_LOGIN_SCRIPT} .Jenkins/create-branch.sh',
						returnStdout: true
			).trim()
			echo "Create branch: ${CREATE_BRANCH_OUT}"
		}
            }
        }
    }
}

