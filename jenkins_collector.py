__author__ = 'peter.ducai@gmail.com'

import requests
import xml.etree.ElementTree as ET


################################
# GLOBAL VALUES (do not abuse) #
################################

# server values
server_ip = "127.0.0.1"  #localhost as default if no IP specified
server_port = "8080"

# job/view values
viewList = []
jobList = []
viewCount = 0
jobCount = 0



#########################
# List views on Jenkins #
#########################
def list_views():
    print("collecting View information from ", server_ip)

    restcall = requests.get('http://{0}:{1}/api/xml?xpath=count(/hudson/view[*])'.format(server_ip, server_port))
    viewCount = int(float(restcall.text))
    print("found {0} Views".format(viewCount))

    i = 1
    while viewCount >= i:
        restcall = requests.get('http://{0}:{1}/api/xml?xpath=/hudson/view[{2}]/name'.format(server_ip, server_port, i))
        root = ET.fromstring(restcall.text)
        print("[ {0} ]".format(root.text))
        viewList.insert(i, root.text)
        list_jobs(root.text)
        i += 1


#########################
# list jobs in view     #
#########################
def list_jobs(view_id):
    restcall = requests.get(
        'http://{0}:{1}/view/{2}/api/xml?xpath=count(/listView/job[*])'.format(server_ip, server_port, view_id))
    jobCount = int(float(restcall.text))

    i = 1
    while jobCount >= i:
        restcall = requests.get(
            'http://{0}:{1}/view/{2}/api/xml?xpath=/listView/job[{3}]/name'.format(server_ip, server_port, view_id, i))
        root = ET.fromstring(restcall.text)
        print("             [ {0} ]".format(root.text))
        get_job_attributes(root.text)
        jobList.insert(i, root.text)
        i += 1


###############################
# get details of specific job #
###############################
def get_job_attributes(job_name):
    restcall = requests.get('http://{0}:{1}/job/{2}/lastBuild/api/xml?xpath=/freeStyleBuild/number[1]'.format(server_ip, server_port, job_name))
    root = ET.fromstring(restcall.text)
    print("               RUN:{0}".format(root.text))
    restcall = requests.get('http://{0}:{1}/job/{2}/lastBuild/api/xml?xpath=/freeStyleBuild/duration[1]'.format(server_ip, server_port, job_name))
    root = ET.fromstring(restcall.text)
    print("               DURATION:{0}".format(root.text))
    restcall = requests.get('http://{0}:{1}/job/{2}/lastBuild/api/xml?xpath=/freeStyleBuild/result[1]'.format(server_ip, server_port, job_name))
    root = ET.fromstring(restcall.text)
    print("               RESULT:{0}".format(root.text))
    restcall = requests.get('http://{0}:{1}/job/{2}/lastBuild/api/xml?xpath=/freeStyleBuild/url[1]'.format(server_ip, server_port, job_name))
    root = ET.fromstring(restcall.text)
    print("               URL:{0}".format(root.text))

def xml_write_view():
    print("writing view data to xml")


def xml_write_all():
    print("writing all to xml")


########################
# MAIN FUNCTION        #
########################

list_views()