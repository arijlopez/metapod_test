import flask
from flask import request
from jenkins_helper import *

app = flask.Flask(__name__)

# app = create_app()

JENKINS_PORT='8080'
JENKINS_URL='http://jenkins'
JENKINS_JOB='run_inspec'
REPORTS_LOCATION='/var/jenkins_home/data/reports'

@app.route('/', methods=['GET'])
def description():
    return 'Api run jenkins jobs and check job status'

@app.route('/runJob', methods=['POST'])
def run_trigger_job():
    PARAMS = request.json
    PARAMS['uuid'] = JenkinsHelper.generate_uuid()
    #print("this is jenkins url variable: ", JENKINS_URL)
    PARAMS['jenkins_url'] = JENKINS_URL if "jenkins_url" not in PARAMS else PARAMS['jenkins_url']
    PARAMS['jenkins_port'] = JENKINS_PORT if "jenkins_port" not in PARAMS else PARAMS['jenkins_port']
    PARAMS['report_name'] = 'inspec' if "report_name" not in PARAMS else PARAMS['report_name']
    PARAMS['ssh_key_name'] = 'metapod_private_key' if "ssh_key_name" not in PARAMS else PARAMS['ssh_key_name']
    PARAMS['jenkins_job'] = JENKINS_JOB if "jenkins_job" not in PARAMS else PARAMS['jenkins_job']
    PARAMS['build_token'] = 'metapod' if "build_token" not in PARAMS else PARAMS['build_token']
    PARAMS['reports_location'] = REPORTS_LOCATION if "reports_location" not in PARAMS else PARAMS['reports_location']
    jenkins_obj = JenkinsHelper(PARAMS['jenkins_url'],PARAMS['jenkins_port'],PARAMS['username'],PARAMS['password'])
    output = jenkins_obj.build_job(PARAMS['jenkins_job'], PARAMS, PARAMS['build_token'])
    return output

@app.route('/checkJobStatus', methods=['POST'])
def run_check_job_status():
    PARAMS = request.json
    PARAMS['jenkins_url'] = JENKINS_URL if "jenkins_url" not in PARAMS else PARAMS['jenkins_url']
    PARAMS['jenkins_port'] = JENKINS_PORT if "jenkins_port" not in PARAMS else PARAMS['jenkins_port']
    PARAMS['jenkins_job'] = JENKINS_JOB if "jenkins_job" not in PARAMS else PARAMS['jenkins_job']
    jenkins_obj = JenkinsHelper(PARAMS['jenkins_url'],PARAMS['jenkins_port'],PARAMS['username'],PARAMS['password'])
    output = jenkins_obj.check_build_status(PARAMS['jenkins_job'], int(PARAMS['build_number']))
    return output

# if __name__ == '__main__':
#     app.run(host='0.0.0.0',debug=True)

if __name__ == "__main__":
    from waitress import serve
    serve(app, host="0.0.0.0", port=5000)
