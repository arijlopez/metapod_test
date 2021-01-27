import jenkins
import time
import uuid
import sys

class JenkinsHelper:
    def __init__(self,url,port,username,password):
        self.jenkins_url = '{}:{}'.format(url,port)
        self.jenkins_server = jenkins.Jenkins(self.jenkins_url, username=username, password=password)
        user = self.jenkins_server.get_whoami()
        version = self.jenkins_server.get_version()
        # print ("Jenkins Version: {}".format(version))
        # print ("Jenkins User: {}".format(user['id']))

    @staticmethod
    def generate_uuid():
        id = str(uuid.uuid4())
        return id

    def build_job(self, name, parameters=None, token=None):
        QUEUE_POLL_INTERVAL = 1
        OVERALL_TIMEOUT = 300 # 5 mins
        elapsed_time = 0
        # next_build_number = self.jenkins_server.get_job_info(name)['nextBuildNumber']
        queue_number = self.jenkins_server.build_job(name, parameters=parameters, token=token)
        # time.sleep(10)
        while True:
            queue_info = self.jenkins_server.get_queue_item(queue_number, depth=0)
            if "executable" not in queue_info:
                time.sleep(1)
            else:
                build_number = queue_info['executable']['number']
                break

            elapsed_time += QUEUE_POLL_INTERVAL
            if elapsed_time > OVERALL_TIMEOUT:
                print(f"{time.ctime()}: Job with queue id: {queue_number} cannot be started \
                url of job is: {self.jenkins_url}, and response: {queue_info}")
                sys.exit()

            # print("this is the queue info :",  queue_info)
        build_info = self.jenkins_server.get_build_info(name, build_number)
        return build_info

    def check_build_status(self, name, build_number, depth=0):
        build_info = self.jenkins_server.get_build_info(name, build_number, depth)
        return build_info
