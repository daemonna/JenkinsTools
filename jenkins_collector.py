__author__ = 'peter.ducai@gmail.com'

import requests
import xml.etree.ElementTree as ET
import getopt, sys, os



################################
# GLOBAL VALUES (do not abuse) #
################################

class jenkins_job:
    name = ""
    run = ""
    url = ""
    duration = ""
    result = ""
    failure = ""
    view = ""



# server values
server_ip = "10.200.10.149"  #localhost as default if no IP specified
server_port = "8080"

# job/view values
viewCount = 0
jobCount = 0
job_array = []
view_from_cli = "n/a"



#########################
# List views on Jenkins #
#########################
def list_views():
    print("collecting View information from ", server_ip)

    restcall = requests.get('http://{0}:{1}/api/xml?xpath=count(/hudson/view[*])'.format(server_ip, server_port),
                            timeout=10)  #first call with timeout
    viewCount = int(float(restcall.text))
    print("found {0} Views".format(viewCount))

    i = 1
    while viewCount >= i:
        restcall = requests.get('http://{0}:{1}/api/xml?xpath=/hudson/view[{2}]/name'.format(server_ip, server_port, i))
        root = ET.fromstring(restcall.text)
        print("[ {0} ]".format(root.text))
        #viewList.insert(i, root.text)
        list_jobs(root.text)
        i += 1


#########################
# list jobs in view     #
#########################
def list_jobs(view_id):
    restcall = requests.get('http://{0}:{1}/view/{2}/api/xml?xpath=count(/*/job[*])'.format(server_ip, server_port, view_id))
    jobCount = int(float(restcall.text))

    i = 1
    while jobCount >= i:
        restcall = requests.get('http://{0}:{1}/view/{2}/api/xml?xpath=/*/job[{3}]/name'.format(server_ip, server_port, view_id, i))
        root = ET.fromstring(restcall.text)
        print("             [ {0} ]".format(root.text))

        #jobList.insert(i, root.text)

        newjob = jenkins_job()
        if view_id != "All":
            newjob.view = view_id
            newjob.name = root.text
            newjob.result = get_job_result(newjob.name)
            newjob.duration = get_job_duration(newjob.name)
            newjob.run = get_job_run(newjob.name)
            newjob.url = get_job_url(newjob.name)
            job_array.append(newjob)
        else:
            print("skiping coz belongs to ALL")

        #print("job {0} and status {1}".format(newjob.name, newjob.result))

        i += 1


###############################
# get details of specific job #
###############################
def get_job_run(jobname):
    restcall = requests.get('http://{0}:{1}/job/{2}/lastBuild/api/xml?xpath=/freeStyleBuild/number[1]'.format(server_ip, server_port, jobname))
    root = ET.fromstring(restcall.text)
    print("               RUN:{0}".format(root.text))
    return root.text

def get_job_duration(jobname):
    restcall = requests.get('http://{0}:{1}/job/{2}/lastBuild/api/xml?xpath=/freeStyleBuild/duration[1]'.format(server_ip, server_port, jobname))
    root = ET.fromstring(restcall.text)
    print("               DURATION:{0}".format(root.text))
    return root.text

def get_job_result(jobname):
    restcall = requests.get('http://{0}:{1}/job/{2}/lastBuild/api/xml?xpath=/freeStyleBuild/result[1]'.format(server_ip, server_port, jobname))
    root = ET.fromstring(restcall.text)
    print("               RESULT:{0}".format(root.text))
    return root.text

def get_job_url(jobname):
    restcall = requests.get('http://{0}:{1}/job/{2}/lastBuild/api/xml?xpath=/freeStyleBuild/url[1]'.format(server_ip, server_port, jobname))
    root = ET.fromstring(restcall.text)
    print("               URL:{0}".format(root.text))
    return root.text



def xml_write_view():   #SubElement(body, 'outline', {'text':group_name})
    print("writing view data to xml")


def xml_write_all():
    print("writing all to xml")


#########################################
#                                       #
# MAIN                                  #
#########################################
def main(argv):
    try:
        opts, args = getopt.getopt(argv, 'h:sip:sport:vw', ['help', 'server-ip', 'server-port', 'view'])
    except getopt.GetoptError:
            usage()
            sys.exit(2)

    for opt, arg in opts:
        if opt in ('-h', '--help'):
            usage()
            sys.exit(2)
        elif opt in ('-sip', '--server-ip'):
            server_ip = opt
        elif opt in ('-sport', '--server-port'):
            server_port = opt
        elif opt in ('-vw', '--view'):
            view_from_cli = opt
        else:
            usage()
            sys.exit(2)
    list_views()
    #print(job_view_set)
    print("we have {0} jobs in qeue".format(job_array.__len__()))



if __name__ == "__main__":
    main(sys.argv[1:]) # [1:] slices off the first argument