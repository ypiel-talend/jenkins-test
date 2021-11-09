def branchName = env.BRANCH_NAME
def selected_repos = ""

pipeline {
    agent { docker { image 'maven:3.3.3' } }
    parameters {
        choice(name: 'Repository',
               choices: ['ALL', 'CONNECTORS-SE', 'CONNECORS-EE', 'CLOUD-COMPONENTS'],
               description: 'Select the repository for which you want to create the maintenance/x.y branch.')
        booleanParam(name: 'DRY_RUN', defaultValue: false, description: 'DRY_RUN mode')
        booleanParam(name: 'DEBUG', defaultValue: false, description: 'DEBUG mode')
    }
    environment {
        DRY_RUN="${params.DRY_RUN}"
        DEBUG="${params.DEBUG}"
    }
    stages {
        stage('compute_parameters') {
	    steps {
		    script {
			def all_repos = [
				'CONNETORS-SE'    : 'git@github.com:Talend/connectors-se.git',
				'CONNETORS-EE'    : 'git@github.com:Talend/connectors-ee.git',
				'CLOUD-COMPONENTS': 'git@github.com:Talend/cloud-components.git'
			    ]
			def selected_repos_list = []
			all_repos.each {
			    if(params.Repository == 'ALL' || params.Repository == it.key) {
				selected_repos_list.add( it.value )
			    }
			}
			selected_repos = selected_repos_list.join(' ');
		    }
            }
        }
        stage('build') {
            steps {
		sh (script: ".Jenkins/create-branch.sh $selected_repos", returnStdout: false)
		input(message: "Please, check above message, and click on continue when ready...")
            }
        }
    }
}

