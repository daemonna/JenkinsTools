__author__ = 'peter.ducai@gmail.com'

import xml.etree.ElementTree as ET
import getopt
import sys
import datetime
import requests
from requests.auth import HTTPDigestAuth


################################
# GLOBAL VALUES (do not abuse) #
################################
generated_on = str(datetime.datetime.now())

class jenkins_job:
    name = ""
    run = ""
    url = ""
    duration = ""
    result = ""
    failure = ""
    view = ""
    view_idx = ""


# server values
#server_ip = "10.200.10.149"  #localhost as default if no IP specified
server_ip = "192.168.100.100"  #localhost as default if no IP specified
server_port = "8080"
USER=""
PASSWORD=""

# job/view values
job_array = []
view_array = []
view_from_cli = "n/a"


# XML elements for xUnit
root = ET.Element('testsuites')
ts = ET.Element('testsuite')
tc = ET.Element('testcase')
fa = ET.Element('failure')


#########################
# List views on Jenkins #
#########################
def list_views():
    print("collecting View information from ", server_ip)


    restcall = requests.get('http://{0}:{1}/api/xml?xpath=string(count(/hudson/view[*]))&wrapper=hudson'.format(server_ip, server_port), auth=HTTPDigestAuth('extERNIDuc', '3ODiskKC'))  #first call with timeout
    print("REQ: {0}".format(restcall.status_code))
    if restcall.status_code == 403:
        print("Connection error...")
        exit(403)

    root = ET.fromstring(restcall.text)
    viewCount = int(root.text)
    print("found {0} Views".format(viewCount))

    i = 1
    while viewCount >= i:
        restcall = requests.get('http://{0}:{1}/api/xml?xpath=/hudson/view[{2}]/name'.format(server_ip, server_port, i))
        root = ET.fromstring(restcall.text)
        print("[view num {0} is {1} ]".format(i, root.text))
        view_array.append(root.text)
        list_jobs(root.text, i)
        i += 1



#########################
# list jobs in view     #
#########################
def list_jobs(view_id, view_idx):
    print("listing jobs for {0}".format(view_id))
    restcall = requests.get('http://{0}:{1}/view/{2}/api/xml?xpath=string(count(/*/job[*]))&wrapper=hudson'.format(server_ip, server_port, view_id))
    root = ET.fromstring(restcall.text)
    jobCount = int(float(root.text))

    i = 1
    while jobCount >= i:
        restcall = requests.get('http://{0}:{1}/view/{2}/api/xml?xpath=/*/job[{3}]/name'.format(server_ip, server_port, view_id, i))
        root = ET.fromstring(restcall.text)
        print("             [ {0} ]".format(root.text))

        newjob = jenkins_job()
        if view_id != "All":
            newjob.view = view_id
            newjob.view_idx = view_idx
            print("               View_idx: {0}".format(view_idx))
            newjob.name = root.text
            newjob.result = get_job_result(newjob.name)
            newjob.duration = get_job_duration(newjob.name)
            newjob.run = get_job_run(newjob.name)
            newjob.url = get_job_url(newjob.name)
            job_array.append(newjob)
        else:
            print("skiping coz belongs to ALL")
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


#############################################
# write all output to xunit compatible xml  #
#############################################

def CDATA(text=None):
    element = ET.Element('![CDATA[')
    element.text = text
    return element

ET._original_serialize_xml = ET._serialize_xml
def _serialize_xml(write, elem, qnames, namespaces):
    if elem.tag == '![CDATA[':
        write("\n<%s%s]]>\n" % (elem.tag, elem.text))
        return
    return ET._original_serialize_xml(write, elem, qnames, namespaces)
ET._serialize_xml = ET._serialize['xml'] = _serialize_xml


# testsuites
def xunit_write_tss():
    print("writing testsuites")
    root.set('tests', '1.0')
    root.set('failures', '6')
    root.set('disabled', '6')
    root.set('errors', '6')
    root.set('time', '6')
    root.set('name', view_name)
    root.append(ET.Comment('Generated on {0} by Jenkins Collector from https://github.com/daemonna/JenkinsTools'.format(generated_on)))

# testsuite
def xunit_write_ts(view_id):
    print("writing testsuite {0}".format(view_id))
    ts.set('name', '{0}'.format(view_id))
    ts.set('status', '6')
    ts.set('time', '6')
    root.append(ts)

# testcase
def xunit_write_tc(job_name):
    print("writing testcase {0}".format(job_name))
    tc.set('name', '{0}'.format(job_name))
    tc.set('revision', '6')
    ts.append(tc)

    if FAIL == 'Y':
        print('writing failure')
        fa.set('message', '1.0')
        ts.append(fa)
        cdata = CDATA("some crappy error output")
        fa.append(cdata)

# finish xml and save it
def xunit_finish_xml():
    tree = ET.ElementTree(root)
    tree.write("page.xml", xml_declaration=True, encoding='utf-8', method="xml")

def generate_xunit():
    print("xUnit generator initialized... {0} views and {1} jobs".format(view_array.__len__(), job_array.__len__()))



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
    generate_xunit()




if __name__ == "__main__":
    main(sys.argv[1:]) # [1:] slices off the first argument