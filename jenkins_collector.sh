#!/bin/bash  

#
# Author : peter.ducai@gmail.com 
# Homepage : 
# License : BSD http://en.wikipedia.org/wiki/BSD_license
# Copyright 2014, peter ducai
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met: 
# 
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer. 
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution. 
# 3. Neither the name of the copyright holder nor the names of its contributors
#    may be used to endorse or promote products derived from this software without
#    specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# Purpose : script to collect Jenkins XML API data and convert them to xUnit compatible format
# Usage : run with --help
#


####################################################################################################
#                                                                                                  #
# GLOBAL VALUES                                                                                    #
####################################################################################################

###################
# TERMINAL COLORS #
###################

NONE='\033[00m'
RED='\033[01;31m'
GREEN='\033[01;32m'
YELLOW='\033[01;33m'
BLACK='\033[30m'
BLUE='\033[34m'
VIOLET='\033[35m'
CYAN='\033[36m'
GREY='\033[37m'

############################
# system values            #
############################
NOW=$(date +"%s-%d-%m-%Y")

################
# HOST values  #
################
IP="127.0.0.1"
PORT="8080"
USER=""
PASSWORD=""

TEMP_DIR="tmp"
REPORT_DIR="reports"
REPORT_FILE=${REPORT_DIR}/report.xml
VIEWS_COUNT=0

declare -A ALL_JOBS



####################################################################################################
#                                                                                                  #
# FUNCTIONS                                                                                        #
####################################################################################################


############################################
# prepare folders for temp storage of xmls #
# Arguments:                               #
#   None                                   #
# Returns:                                 #
#   None                                   #
############################################
prepare_tmp_folders() {
    if [[ ! -d ${TEMP_DIR} ]];then
        mkdir ${TEMP_DIR}
    fi
    
    if [[ ! -d ${REPORT_DIR} ]];then
        mkdir ${REPORT_DIR}
    fi
}


#####################################
# get number of Views from Jenkins  #
# Arguments:                        #
#   None                            #
# Returns:                          #
#   None                            # 
#####################################
collect_views_count() {
    echo -e "[collect_views_from_jenkins]"
    #DO NOT REMOVE QUOTES, otherwise it won't work as it should
    wget -q -O ${TEMP_DIR}/view_count.xml --auth-no-challenge --http-user=${USER} --http-password=${PASSWORD} "http://${IP}:${PORT}/api/xml?xpath=string(count(/hudson/view[*]))&wrapper=hudson"
    VIEWS_COUNT=$(cat ${TEMP_DIR}/view_count.xml | grep '<hudson' | cut -d '>' -f 2 | cut -d '<' -f 1)
    echo -e "got ${VIEWS_COUNT} views"
}


##############################
# collect name of each view  #
##############################
collect_view_names() {
    echo -e "[collect_view_names]"
    printf "" > ${TEMP_DIR}/view_names.xml
    
    local i=1
    while [ $((${VIEWS_COUNT})) -ge ${i} ]
    do
        wget -q -O ${TEMP_DIR}/jobsview_${i}.xml --auth-no-challenge --http-user=${USER} --http-password=${PASSWORD} "http://${IP}:${PORT}/api/xml?xpath=/hudson/view[${i}]/name"
        echo $(cat ${TEMP_DIR}/jobsview_${i}.xml | grep '<name' | cut -d '>' -f 2 | cut -d '<' -f 1) >> ${TEMP_DIR}/view_names.xml
        rm -rf ${TEMP_DIR}/jobsview_${i}.xml
        i=$(($i+1))
    done  
    
    for jv in $(cat ${TEMP_DIR}/view_names.xml)
    do
        collect_job_count_per_view ${jv}
    done

}

################################
# get number of jobs in view   #
################################
collect_job_count_per_view() {
    local job_name=""
    echo -e "[collect_job_count_per_view] $1"
    wget -q -O ${TEMP_DIR}/jobsview_${i}.xml --auth-no-challenge --http-user=${USER} --http-password=${PASSWORD} "http://${IP}:${PORT}/view/$1/api/xml"
    tidy -q -xml ${TEMP_DIR}/jobsview_${i}.xml > ${TEMP_DIR}/jobsview_${i}_tidy.xml
    cat ${TEMP_DIR}/jobsview_${i}_tidy.xml|grep name > ${TEMP_DIR}/jobsview_${i}_names.xml
    for n in $(head -n -1 ${TEMP_DIR}/jobsview_${i}_names.xml)
    do        
        collect_job_info $(echo $n | grep '<name' | cut -d '>' -f 2 | cut -d '<' -f 1)
    done
    

    rm -rf *_tidy.xml
}


###########################
# get info about each job #
# Arguments:              #
#   job_name              #
# Returns:                #
#   None                  #
###########################
collect_job_info() {
    echo -e "        [collect_job_info] $1"    
    
    #DO NOT REMOVE QUOTES, otherwise it won't work as it should
    wget -q -O ${TEMP_DIR}/id.xml --auth-no-challenge --http-user=${USER} --http-password=${PASSWORD} "http://${IP}:${PORT}/job/$1/lastBuild/api/xml?xpath=/freeStyleBuild/id[1]"
    wget -q -O ${TEMP_DIR}/fullDisplayName.xml --auth-no-challenge --http-user=${USER} --http-password=${PASSWORD} "http://${IP}:${PORT}/job/$1/lastBuild/api/xml?xpath=/freeStyleBuild/fullDisplayName[1]"
    wget -q -O ${TEMP_DIR}/revision.xml --auth-no-challenge --http-user=${USER} --http-password=${PASSWORD} "http://${IP}:${PORT}/job/$1/lastBuild/api/xml?xpath=/freeStyleBuild/changeSet/item/revision[1]"
    wget -q -O ${TEMP_DIR}/building.xml --auth-no-challenge --http-user=${USER} --http-password=${PASSWORD} "http://${IP}:${PORT}/job/$1/lastBuild/api/xml?xpath=/freeStyleBuild/building[1]"
    wget -q -O ${TEMP_DIR}/duration.xml --auth-no-challenge --http-user=${USER} --http-password=${PASSWORD} "http://${IP}:${PORT}/job/$1/lastBuild/api/xml?xpath=/freeStyleBuild/duration[1]"
    wget -q -O ${TEMP_DIR}/result.xml --auth-no-challenge --http-user=${USER} --http-password=${PASSWORD} "http://${IP}:${PORT}/job/$1/lastBuild/api/xml?xpath=/freeStyleBuild/result[1]"
    wget -q -O ${TEMP_DIR}/run.xml --auth-no-challenge --http-user=${USER} --http-password=${PASSWORD} "http://${IP}:${PORT}/job/$1/api/xml?xpath=/freeStyleProject/lastBuild/number[1]"


    REVISION=$(cat $TEMP_DIR/revision.xml | grep '<revision' | cut -d '>' -f 2 | cut -d '<' -f 1)
    BUILDING=$(cat $TEMP_DIR/building.xml | grep '<building' | cut -d '>' -f 2 | cut -d '<' -f 1)
    DURATION=$(cat $TEMP_DIR/duration.xml | grep '<duration' | cut -d '>' -f 2 | cut -d '<' -f 1)
    RESULT=$(cat $TEMP_DIR/result.xml | grep '<result' | cut -d '>' -f 2 | cut -d '<' -f 1)
    RUN=$(cat $TEMP_DIR/run.xml | grep '<number' | cut -d '>' -f 2 | cut -d '<' -f 1)
    
    echo -e "                [RUN] ${RUN}" 
    echo -e "                [RESULT] ${RESULT}" 
    if [[ ${RESULT} == "FAILURE" ]];then        
        echo -e "                [Failure URL] http://${IP}:${PORT}/job/$1/${RUN}/console"
    fi
    echo -e "                [DURATION] ${DURATION}"
}



############################################################
#                                                          #
# XML Processing functions                                 #
############################################################


######################
# write xml version  #
# Arguments:         #
#   None             #
# Returns:           #
#   None             #
######################
write_xml_head() {
    echo -e "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" > ${REPORT_FILE}
}


###############################
# write testsuites element    #
# Arguments:                  #
#   testsuites_name           #
#   failures                  #
#   time                      #
# Returns:                    #
#   None                      #
###############################
write_xml_testsuites() {
    if [[ "${RESULT}" == "FAILURE" ]];then
        echo -e "<testsuites name=\"${TSS_NAME}\" tests=\"1\" failures=\"1\" disabled=\"0\" errors=\"0\" time=\"${DURATION}\">" >> ${REPORT_FILE}
    else
        echo -e "<testsuites name=\"${TSS_NAME}\" tests=\"1\" failures=\"0\" disabled=\"0\" errors=\"0\" time=\"${DURATION}\">" >> ${REPORT_FILE}
    fi
}

write_xml_testsuite() {
    if [[ "${RESULT}" == "FAILURE" ]];then
        echo -e "<testsuite name=\"${TS_NAME}\" tests=\"1\" failures=\"1\" disabled=\"0\" errors=\"0\" time=\"${DURATION}\">" >> ${REPORT_FILE}
    else
        echo -e "<testsuite name=\"${TS_NAME}\" tests=\"1\" failures=\"0\" disabled=\"0\" errors=\"0\" time=\"${DURATION}\">" >> ${REPORT_FILE}
    fi
}

write_xml_testcase() {
    echo -e "            <testcase name=\"${JB_NAME}\" status=\"run\" time=\"${DURATION}\" classname=\"${TS_NAME}\"/>" >> ${REPORT_FILE}
    }
    
    

write_xml_testcase_failure() {
    if [[ "${RESULT}" == "FAILURE" ]];then
        echo -e "        <failure message=\"http://${IP}:${PORT}/job/$1/${RUN}/console\" type=\"\">" >> ${OUTF}
        echo -e "          <![CDATA[" >> ${OUTF}
        echo -e "          http://${IP}:${PORT}/job/$1/${RUN}/console" >> ${OUTF}
        echo -e "          ]]>" >> ${OUTF}
        echo -e "        </failure>" >> ${OUTF}
    fi
}

write_xml_tail() {
    echo -e "    </testsuite>" >> ${REPORT_FILE}
    echo -e "</testsuites>" >> ${REPORT_FILE}
}

prepare_tmp_folders
collect_views_count
collect_view_names








