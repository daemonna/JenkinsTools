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
TCS_COUNT=0
ALL_FAILURES=0
FAILURES_PER_VIEW=()
TC_PER_VIEW=()
VIEW_NAMES=()

#declare -A ALL_JOBS



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


###########################
# get name of each view   #
# Arguments:              #
#   None                  #
# Returns:                #
#   None                  #
###########################
collect_view_names() {
    echo -e "[collect_view_names]"
    printf "" > ${TEMP_DIR}/view_names.xml
    
    local i=1
    while [ $((${VIEWS_COUNT})) -ge ${i} ]
    do
        wget -q -O ${TEMP_DIR}/view_${i}.xml --auth-no-challenge --http-user=${USER} --http-password=${PASSWORD} "http://${IP}:${PORT}/api/xml?xpath=/hudson/view[${i}]/name"
        echo $(cat ${TEMP_DIR}/view_${i}.xml | grep '<name' | cut -d '>' -f 2 | cut -d '<' -f 1) >> ${TEMP_DIR}/view_names.xml
        i=$(($i+1))
    done  
    
    local vindex=0 #view index for tracking failures per view
    for jv in $(cat ${TEMP_DIR}/view_names.xml)
    do
        collect_job_count_per_view ${jv} ${vindex}
        VIEW_NAMES[${vindex}]=${jv}
        vindex=$((${vindex}+1))
    done
    
    echo -e "GOT $VIEWS_COUNT views"

}

###########################
# count jobs per view     #
# Arguments:              #
#   view_name             #
#   view_index            #
# Returns:                #
#   None                  #
###########################
collect_job_count_per_view() {

    echo -e "[collect_job_count_per_view] $1"
    wget -q -O ${TEMP_DIR}/view_$1_jobs.xml --auth-no-challenge --http-user=${USER} --http-password=${PASSWORD} "http://${IP}:${PORT}/view/$1/api/xml"
    tidy -q -xml ${TEMP_DIR}/view_$1_jobs.xml > ${TEMP_DIR}/view_$1_jobs_tidy.xml
    cat ${TEMP_DIR}/view_$1_jobs_tidy.xml|grep name > ${TEMP_DIR}/view_$1_jobs_name.xml
    
    for n in $(head -n -1 ${TEMP_DIR}/view_$1_jobs_name.xml)
    do        
        echo "collect_job_info $n"
        collect_job_info $(echo $n | grep '<name' | cut -d '>' -f 2 | cut -d '<' -f 1) $2
    done
}


###########################
# get info about each job #
# Arguments:              #
#   job_name              #
# Returns:                #
#   None                  #
###########################
collect_job_info() {
    echo -e "        [collect_job_info] view_name:$1 vindex:$2"    
    TC_PER_VIEW[$2]=$(($((${TC_PER_VIEW[$2]}))+1))
    TCS_COUNT=$((${TCS_COUNT}+1))
    
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
        ALL_FAILURES=$((${ALL_FAILURES}+1))
        FAILURES_PER_VIEW[$2]=$((${FAILURES_PER_VIEW[$2]}+1))
    else
        FAILURES_PER_VIEW[$2]=$((${FAILURES_PER_VIEW[$2]}+0))
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
    echo -e "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
    echo -e "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" > ${REPORT_FILE}
}


###############################
# write testsuites element    #
# Arguments:                  #
#   None                      #
# Returns:                    #
#   None                      #
###############################
write_xml_testsuites() {
    echo -e "<testsuites name=\"all_testsuites\" tests=\"${ALL_TCS_COUNT}\" failures=\"${ALL_FAILURES}\" disabled=\"0\" errors=\"0\" time=\"0\">"
    echo -e "<testsuites name=\"all_testsuites\" tests=\"${ALL_TCS_COUNT}\" failures=\"${ALL_FAILURES}\" disabled=\"0\" errors=\"0\" time=\"0\">" >> ${REPORT_FILE}
}


###############################
# write testsuite element     #
# Arguments:                  #
#   testsuite_name            #
#   tests                     #
#   failures                  #
#   disabled                  #
#   errors                    #
#   time                      #
# Returns:                    #
#   None                      #
###############################
write_xml_testsuite() {
    echo -e "    <testsuite name=\"$1\" tests=\"$2\" failures=\"$3\" disabled=\"$4\" errors=\"$5\" time=\"$6\">"
    echo -e "    <testsuite name=\"$1\" tests=\"$2\" failures=\"$3\" disabled=\"$4\" errors=\"$5\" time=\"$6\">" >> ${REPORT_FILE}
}


###############################
# write testcase element      #
# Arguments:                  #
#   testcase_name             #
#   status                    #
#   time                      #
#   classname                 #
# Returns:                    #
#   None                      #
###############################
write_xml_testcase() {
    echo -e "            <testcase name=\"$1\" status=\"run\" time=\"$3\" classname=\"$4\"/>" 
    echo -e "            <testcase name=\"$1\" status=\"run\" time=\"$3\" classname=\"$4\"/>" >> ${REPORT_FILE}
}
    
    
###############################
# write testcase failure      #
# Arguments:                  #
#   job_name                  #
#   run number                #
# Returns:                    #
#   None                      #
###############################
write_xml_testcase_failure() {
    echo -e "[write_xml_testcase_failure]"
    if [[ "${RESULT}" == "FAILURE" ]];then
        echo -e "        <failure message=\"http://${IP}:${PORT}/job/$1/$2/console\" type=\"\">" >> ${OUTF}
        echo -e "          <![CDATA[" >> ${OUTF}
        echo -e "          http://${IP}:${PORT}/job/$1/$2/console" >> ${OUTF}
        echo -e "          ]]>" >> ${OUTF}
        echo -e "        </failure>" >> ${OUTF}
    fi
}


###############################
# write ending elements       #
# Arguments:                  #
#   None                      #
# Returns:                    #
#   None                      #
###############################
write_xml_tail() {
    echo -e "</testsuites>"
    echo -e "</testsuites>" >> ${REPORT_FILE}
}

###############################
# generate xUnit report       #
# Arguments:                  #
#   None                      #
# Returns:                    #
#   None                      #
###############################
generate_full_xml() {

    echo -e "[XML GENERATOR] combining XML elements....."
    write_xml_head
    write_xml_testsuites
    

    for jv in $(cat ${TEMP_DIR}/view_names.xml)
    do
        write_xml_testsuite ${jv} ${TC_PER_VIEW[${jv}]} ${FAILURES_PER_VIEW[${jv}]}
        
       
        for n in $(head -n -1 ${TEMP_DIR}/view_${jv}_jobs_name.xml)
        do        
            jname=$(echo $n | grep '<name' | cut -d '>' -f 2 | cut -d '<' -f 1)
            write_xml_testcase ${jname}
        done
    done
    
    write_xml_tail
}



############################################################
#                                                          #
# Help and cleanup functions                               #
############################################################

###############################
# remove temporary directory  #
# Arguments:                  #
#   None                      #
# Returns:                    #
#   None                      #
###############################
clean_tmp() {
    rm -rf ${TEMP_DIR}
}


###############################
# print all global parameters #
# Arguments:                  #
#   None                      #
# Returns:                    #
#   None                      #
###############################
print_parameters() {
    echo -e "DEFAULT VALUES:"
    echo -e "------------------------------------------------------"
    echo -e "IP: ${IP}"
    echo -e "PORT: ${PORT}"
    echo -e "USER: ${USER}"
    echo -e "PASSWORD: ${PASSWORD}"
    echo -e "------------------------------------------------------"
}


###############################
# print usage                 #
# Arguments:                  #
#   None                      #
# Returns:                    #
#   None                      #
###############################
print_usage() {
    echo -e "USAGE: (all parameters are optional!)"
    echo -e "--print-values              print default values"
    echo -e "--server-ip=\"127.0.0.1\"     set IP address of Jenkins server"
    echo -e "--server-port=\"8080\"        set port of Jenkins server"
    echo -e "--user=\"username\"           set username for authentication"
    echo -e "--password=\"pass\"           set password for user authentication"
}


###############################
# print nice banner           #
# Arguments:                  #
#   None                      #
# Returns:                    #
#   None                      #
###############################
print_banner() {
    echo -e "     ____.              __   .__               "
    echo -e "    |    | ____   ____ |  | _|__| ____   ______"
    echo -e "    |    |/ __ \ /    \|  |/ /  |/    \ /  ___/"
    echo -e "/\__|    \  ___/|   |  \    <|  |   |  \\___ \\"
    echo -e "\________|\___  >___|  /__|_ \__|___|  /____  >"
    echo -e "              \/     \/     \/       \/     \/ "
    echo -e "                                               XML Collector"
    echo -e "----------------------------------------------------------------------------------"
    echo -e "script to collect Jenkins XML API data and convert them to xUnit compatible format"
    echo -e "----------------------------------------------------------------------------------"
}


recount_failures() {
    ALLF=0
    OTHERF=0
    jj=0
    END=$((${#VIEW_NAMES[*]}))

    echo -e "FAILURE SUMMARY:"
    echo -e "total TCs: ${ALL_TCS_COUNT}"
    while [[ $jj -lt $END ]]
    do
        echo -e "${VIEW_NAMES[$jj]} got ${TC_PER_VIEW[$jj]} testcases and ${FAILURES_PER_VIEW[$jj]} failures"
        if [[ "${VIEW_NAMES[$jj]}" == "All" ]];then
            ALLF=$(($((${ALLF}))+$((${FAILURES_PER_VIEW[$jj]}))))
        else
            OTHERF=$(($((${OTHERF}))+$((${FAILURES_PER_VIEW[$jj]}))))
        fi
        
        ((jj = jj + 1))
    done
}

####################################################################################################
#                                                                                                  #
# MAIN FUNCTION                                                                                    #
####################################################################################################

#######################
# process parameters  #
#######################
for i in "$@"
do
case "$i" in
    --help) print_banner
        print_usage
        exit
        ;;
    --server-ip=*) IP="${i#*=}"
        ;;
    --server-port=*) PORT="${i#*=}"
        ;;
    --user=*) USER="${i#*=}"
        ;;
    --password=*) PASSWORD="${i#*=}"
        ;;
    --print-values) print_parameters
        exit
        ;;
    *) echo "WRONG PARAMETER!!!"
        print_banner 
        print_usage
        exit
        ;;
esac
done

prepare_tmp_folders
collect_views_count
collect_view_names
recount_failures
generate_full_xml

#clean_tmp

##############################
# END OF MAIN                #
##############################
exit $?




