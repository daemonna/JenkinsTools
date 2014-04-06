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

<<<<<<< HEAD

class jenkins_job(object):
    """__init__() functions as the class constructor"""

    def __init__(self, name=None, shortname=None, run=None, url=None, duration=None, result=None, failure=None,
                 view=None,
                 view_idx=None):
        self.name = name
        self.shortname = shortname
        self.run = run
        self.url = url
        self.duration = duration
        self.result = result
        self.failure = failure
        self.view = view
        self.view_idx = view_idx


class jenkins_view(object):
    """__init__() functions as the class constructor"""

    def __init__(self, name=None, idx=None, status=None, time=None):
        self.name = name
        self.idx = idx
        self.status = status
        self.time = time
=======
class jenkins_job:
    name = ""
    run = ""
    url = ""
    duration = ""
    result = ""
    failure = ""
    view = ""
    view_idx = ""
>>>>>>> 60bff4844245ffda13526320edc3dc5f73a673f2


# server values
#server_ip = "10.200.10.149"  #localhost as default if no IP specified
<<<<<<< HEAD
#server_ip = "192.168.100.100"  #localhost as default if no IP specified
server_ip = "localhost"
server_port = "8080"
USER = "fakeuser"
PASSWORD = "fake123"
=======
server_ip = "192.168.100.100"  #localhost as default if no IP specified
server_port = "8080"
USER=""
PASSWORD=""
>>>>>>> 60bff4844245ffda13526320edc3dc5f73a673f2

# job/view values
job_array = []
view_array = []
view_from_cli = "n/a"


# XML elements for xUnit
root = ET.Element('testsuites')
ts = ET.Element('testsuite')
tc = ET.Element('testcase')
fa = ET.Element('failure')

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

<<<<<<< HEAD
    restcall = requests.get(
        'http://{0}:{1}/api/xml?xpath=string(count(/hudson/view[*]))&wrapper=hudson'.format(server_ip, server_port),
        auth=HTTPDigestAuth(USER, PASSWORD))  #first call with timeout
=======

    restcall = requests.get('http://{0}:{1}/api/xml?xpath=string(count(/hudson/view[*]))&wrapper=hudson'.format(server_ip, server_port), auth=HTTPDigestAuth('extERNIDuc', '3ODiskKC'))  #first call with timeout
>>>>>>> 60bff4844245ffda13526320edc3dc5f73a673f2
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
<<<<<<< HEAD
        view = jenkins_view()
        view.name = root.text
        view.idx = i
        view_array.append(view)
=======
        view_array.append(root.text)
        list_jobs(root.text, i)
>>>>>>> 60bff4844245ffda13526320edc3dc5f73a673f2
        i += 1

    print("View listing FINISHED")



#########################
# list jobs in view     #
#########################
<<<<<<< HEAD
def list_jobs(idx):
    print("[list_jobs] {0}".format(idx))
    print('calling http://{0}:{1}/view/{2}/api/xml?xpath=string(count(/*/job[*]))&wrapper=hudson'.format(server_ip, server_port,
                                                                                               view_array[idx].name))
    restcall = requests.get(
        'http://{0}:{1}/view/{2}/api/xml?xpath=string(count(/*/job[*]))&wrapper=hudson'.format(server_ip, server_port,
                                                                                               view_array[idx].name))
    root = ET.fromstring(restcall.text)
    ET.dump(root)
    jobCount = int(float(root.text))
    print("JOBCOUNT is {0}".format(jobCount))

    i = 0
    while jobCount > i:
        #print(' requesting http://{0}:{1}/view/{2}/api/xml?xpath=/*/job[{3}]/name'.format(server_ip, server_port, view_array[idx].name, i+1))
        restcall = requests.get(
            'http://{0}:{1}/view/{2}/api/xml?xpath=/*/job[{3}]/name'.format(server_ip, server_port,
                                                                            view_array[idx].name, i+1))
        root = ET.fromstring(restcall.text)
        ET.dump(root)
        #print("             job [ {0} ]".format(root.text))

        newjob = jenkins_job()
        print("OUTSIDE job idx {0}".format(idx))
        if view_array[idx].name != "All":
            print("INSIDE job idx {0}".format(idx))
            newjob.view = view_array[idx].name
            newjob.view_idx = idx
            #print("               View_idx: {0}".format(idx))
            newjob.name = root.text
            newjob.result = get_job_result(root.text)
            newjob.duration = get_job_duration(root.text)
            newjob.run = get_job_run(root.text)
            newjob.url = get_job_url(root.text)
            job_array.append(newjob)
            print("job created~~~")
            #print("{0} added to {1}".format(job_array[job_array.__len__() - 1].name, job_array[job_array.__len__() - 1].view))
        else:
            print("{0} already in ALL".format(view_array[idx].name))
=======
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
>>>>>>> 60bff4844245ffda13526320edc3dc5f73a673f2
        i += 1


###############################
# get details of specific job #
###############################
def get_job_run(jobname):
<<<<<<< HEAD
    #print("[get_job_run] with {0}".format(jobname))
    restcall = requests.get(
        'http://{0}:{1}/job/{2}/lastBuild/api/xml?xpath=/freeStyleBuild/number[1]'.format(server_ip, server_port,
                                                                                          jobname))
    root = ET.fromstring(restcall.text)
    #print("               RUN:{0}".format(root.text))
    return root.text


def get_job_duration(jobname):
    #print("[get_job_duration] with {0}".format(jobname))
    restcall = requests.get(
        'http://{0}:{1}/job/{2}/lastBuild/api/xml?xpath=/freeStyleBuild/duration[1]'.format(server_ip, server_port,
                                                                                            jobname))
    root = ET.fromstring(restcall.text)
    #print("               DURATION:{0}".format(root.text))
    return root.text


def get_job_result(jobname):
    #print("[get_job_result] with {0}".format(jobname))
    restcall = requests.get(
        'http://{0}:{1}/job/{2}/lastBuild/api/xml?xpath=/freeStyleBuild/result[1]'.format(server_ip, server_port,
                                                                                          jobname))
    root = ET.fromstring(restcall.text)
    #print("               RESULT:{0}".format(root.text))
    return root.text


def get_job_url(jobname):
    #print("[get_job_url] with {0}".format(jobname))
    restcall = requests.get(
        'http://{0}:{1}/job/{2}/lastBuild/api/xml?xpath=/freeStyleBuild/url[1]'.format(server_ip, server_port, jobname))
    root = ET.fromstring(restcall.text)
    #print("               URL:{0}".format(root.text))
=======
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
>>>>>>> 60bff4844245ffda13526320edc3dc5f73a673f2
    return root.text


#############################################
# write all output to xunit compatible xml  #
#############################################

def CDATA(text=None):
    element = ET.Element('![CDATA[')
    element.text = text
    return element

<<<<<<< HEAD

ET._original_serialize_xml = ET._serialize_xml


=======
ET._original_serialize_xml = ET._serialize_xml
>>>>>>> 60bff4844245ffda13526320edc3dc5f73a673f2
def _serialize_xml(write, elem, qnames, namespaces):
    if elem.tag == '![CDATA[':
        write("\n<%s%s]]>\n" % (elem.tag, elem.text))
        return
    return ET._original_serialize_xml(write, elem, qnames, namespaces)
<<<<<<< HEAD


=======
>>>>>>> 60bff4844245ffda13526320edc3dc5f73a673f2
ET._serialize_xml = ET._serialize['xml'] = _serialize_xml


# testsuites, only 1 element
def xunit_write_tss():
<<<<<<< HEAD
    #print("writing testsuites")
    root.set('tests', '{0}'.format(job_array.__len__()))
=======
    print("writing testsuites")
    root.set('tests', job_array.__len__())
>>>>>>> 60bff4844245ffda13526320edc3dc5f73a673f2
    root.set('failures', '6')
    root.set('disabled', '6')
    root.set('errors', '6')
    root.set('time', '6')
    root.set('name', 'somename')
<<<<<<< HEAD
    root.append(ET.Comment(
        'Generated on {0} by Jenkins Collector from https://github.com/daemonna/JenkinsTools'.format(generated_on)))
    ET.dump(root)


# testsuite
def xunit_write_ts(idx):
    #print("writing testsuite {0}".format(view_array[idx].name))
    ts.set('name', '{0}'.format(view_array[idx].name))
    ts.set('status', '{0}'.format(view_array[idx].status))
    ts.set('time', '{0}'.format(view_array[idx].time))
    root.append(ts)
    ET.dump(ts)


# testcase
def xunit_write_tc(vidx):
    print("[xunit_write_tc]")
    #print("writing testcase {0}".format(job_array[idx].name))
    jx = 0
    while job_array.__len__() > jx:
        #print("got a job {0} in view {1}".format(job_array[jx].name, view_array[idx].name))
        if view_array[vidx].name == job_array[jx].view:
            tc.set('name', '{0}'.format(job_array[jx].name))
            tc.set('status', '{0}'.format(job_array[jx].status))
            tc.set('time', '{0}')
            ET.dump(tc)
        jx += 1



        #tc.set('name', '{0}'.format(job_array[vidx].name))
        #tc.set('revision', '6')
        #ts.append(tc)

        #if FAIL == 'Y':
        #print('writing failure')
        #fa.set('message', '1.0')
        #ts.append(fa)
        #cdata = CDATA("some crappy error output")
        #fa.append(cdata)

=======
    root.append(ET.Comment('Generated on {0} by Jenkins Collector from https://github.com/daemonna/JenkinsTools'.format(generated_on)))

# testsuite
def xunit_write_ts(view_id):
    print("writing testsuite {0}".format(view_id))
    ts.set('name', '{0}'.format(view_id))
    ts.set('status', '6')
    ts.set('time', '6')
    root.append(ts)
    print("appending...")

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
>>>>>>> 60bff4844245ffda13526320edc3dc5f73a673f2

# finish xml and save it
def xunit_finish_xml():
    tree = ET.ElementTree(root)
    tree.write("page.xml", xml_declaration=True, encoding='utf-8', method="xml")

<<<<<<< HEAD

def generate_xunit():
    x = 0
    y = 0
    print("# XML GENERATOR ### xUnit generator initialized... {0} views and {1} jobs".format(view_array.__len__(),
                                                                                             job_array.__len__()))
    xunit_write_tss()

    while view_array.__len__() > x:
        xunit_write_ts(x)
        #while job_array.__len__() > y:
        #xunit_write_tc(y)
        #y += 1
        x += 1


=======
def generate_xunit():
    x = 0
    print("xUnit generator initialized... {0} views and {1} jobs".format(view_array.__len__(), job_array.__len__()))
    xunit_write_tss()

    while view_array.__len__() > x:
        xunit_write_ts(view_array[x])
        x += 1



>>>>>>> 60bff4844245ffda13526320edc3dc5f73a673f2
#########################################
#                                       #
# MAIN                                  #
#########################################
def main(argv):
<<<<<<< HEAD
    vl = 0
    try:
        opts, args = getopt.getopt(argv, 'h:sip:sport:vw', ['help', 'server-ip', 'server-port', 'view'])
    except getopt.GetoptError:
        usage()
        sys.exit(2)
=======
    try:
        opts, args = getopt.getopt(argv, 'h:sip:sport:vw', ['help', 'server-ip', 'server-port', 'view'])
    except getopt.GetoptError:
            usage()
            sys.exit(2)
>>>>>>> 60bff4844245ffda13526320edc3dc5f73a673f2

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
<<<<<<< HEAD
    while view_array.__len__() > vl:
        print("checking jobs in {0}:{1}".format(view_array[vl].idx, view_array[vl].name))
        list_jobs(view_array[vl].idx)
        vl += 1
    generate_xunit()


if __name__ == "__main__":
    main(sys.argv[1:])  # [1:] slices off the first argument
=======
    generate_xunit()




if __name__ == "__main__":
    main(sys.argv[1:]) # [1:] slices off the first argument
>>>>>>> 60bff4844245ffda13526320edc3dc5f73a673f2
