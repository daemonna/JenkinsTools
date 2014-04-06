#!/bin/bash

##########################################################################################
#Copyright by peter.ducai@gmail.com                                                              #
#project: generic                                                                        #
#description: generic Jenkins installer (for Ubuntu) including plugins installation      #
#coding guidelines: http://google-styleguide.googlecode.com/svn/trunk/shell.xml          #
##########################################################################################


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

#############################
# check if user is root     #
#############################
if [ $(id -u) != "0" ]; then
  echo -e "${RED}"
  echo -e "###################################################"
  echo -e "# WARNING!!! NOT ROOT USER                        #"
  echo -e "# YOU NEED TO BE root TO RUN THIS SCRIPT {sudo}   #"
  echo -e "###################################################"
  echo -e "${NONE}" && tput sgr0
  exit
else
  echo "running as root.. OK"
fi



#####################
# GLOBAL VARIABLES  #
#####################
export JENKINS_HOME="/var/lib/jenkins"
BACKUP_DIR="/.jenkins_backup"
NOW=$(date +"%s-%d-%m-%Y")



############################
#install required software #
############################ 
install_prereqs() {
#remove conflicting jenkins-common
  apt-get update
  echo "removing old conflicting packages"
  apt-get remove jenkins jenkins-common
  apt-get purge jenkins jenkins-common

#install basic usefull software    
  echo "installing prerequisities"
  apt-get update
  apt-get upgrade -y
  apt-get install vim nmap tcpdump mc locate p7zip nginx ssh python-software-properties subversion -y
  
#delete OpenJDK and install Oracle JDK for better compatibility
  apt-get purge openjdk-*
  rm -rf /var/cache/jenkins
  add-apt-repository ppa:webupd8team/java
  apt-get update
  apt-get install oracle-java7-installer -y
  apt-get install oracle-java7-set-default -y
}


################################################
# setup repo and install stable Jenkins        #
################################################
install_jenkins() {
#check if apt/source.list contains new Jenkins Repository
  REPO_CHECK=`cat /etc/apt/sources.list|grep pkg.jenkins-ci.org/debian-stable|wc -l`
  if [[ "${REPO_CHECK}" -ge "1" ]]
  then
    echo "${GREEN}/etc/apt/sources.list ALREADY CONTAINS http://pkg.jenkins-ci.org/debian-stable REPOSITORY ${NONE}"
  else
    echo "Adding Jenkins repo to /etc/apt/sources.list"
    wget -q -O - http://pkg.jenkins-ci.org/debian-stable/jenkins-ci.org.key | sudo apt-key add -
    echo "backing up /etc/apt/sources.list"
    cp /etc/apt/sources.list /etc/apt/sources.list.backup  
    echo "deb http://pkg.jenkins-ci.org/debian-stable binary/" >> /etc/apt/sources.list
  fi

#update apt and install new LTS Jenkins
  apt-get update
  apt-get install jenkins -y
}


#########################################
# completely purge old Ubuntu Jenkins   #
#########################################
remove_jenkins() {
  apt-get purge jenkins jenkins-common -y
}


#################################################
# download jenkins-cli.jar (Jenkins CLI tool)   #
#################################################
download_cli(){
  wget -O $JENKINS_HOME/jenkins-cli.jar http://localhost:8080/jnlpJars/jenkins-cli.jar
  chown jenkins:nogroup $JENKINS_HOME/jenkins-cli.jar
}


###################################
# list available config.xml files #
###################################
list_configs() {
  echo "-----------------------------------------------------"
  echo -e "-${YELLOW} AVAILABLE CONFIG FILES:      ${NONE}  -"
  echo "-----------------------------------------------------"
  ls $BACKUP_DIR |grep xml
  echo "-----------------------------------------------------"
}
 

###########################################
# set one of available configs as default #
###########################################
set_config() {
  if [[ -z "$1" ]];
  then
    echo -e "${RED}Missing second parameter CONFIG file! \$2 is $1 ${NONE}"
  else
    cp ${BACKUP_DIR}/$1 $JENKINS_HOME/config.xml
  fi
}


##############################
# backup current config.xml  #
##############################
backup_current_config() {
  echo "Write name of file where you want to backup your config file (without .xml extension)."
  read BK_CONF
  #trim all white spaces
  BK_CONF=$(echo $BK_CONF| tr -d ' ')
  echo "saving $JENKINS_HOME/config.xml ${BACKUP_DIR}/${BK_CONF}_${NOW}.xml"
  cp $JENKINS_HOME/config.xml ${BACKUP_DIR}/${BK_CONF}_${NOW}.xml
  # log it to history
  echo "[$(date)] backing up config, $JENKINS_HOME/config.xml -> ${BACKUP_DIR}/${BK_CONF}_${NOW}.xml" >> $BACKUP_DIR/history
}


backup_history_preparation() {
  echo "preparing history.."
#if backup dir doesn't work, 
  if [[ ! -d "$BACKUP_DIR" ]]; then
    echo "no history file found, creating one.."
    mkdir $BACKUP_DIR
    chown jenkins:nogroup $BACKUP_DIR
    chmod 750 $BACKUP_DIR
    touch $BACKUP_DIR/history
    chown jenkins:nogroup $BACKUP_DIR/history
    echo "[$(date)] Initial history setup" > $BACKUP_DIR/history
  fi  
  echo "history file prepared.."
}


#######################################
# create single backup with timestamp #
#######################################
do_one_time_backup() {
  echo "one time backup starting..."  
  backup_jobs
  backup_current_config
}


############################################
# create reocurring backup in cron         #
############################################
set_cron_backup() { #TODO
  echo "0 0 * * * tar -zcvf /jenkins_${NOW}_full-backup.tgz / --exclude=${JENKINS_HOME}/workspace" >> /var/spool/cron/crontabs/root
  echo "daily backup set in Cron.."
}

############################################
# backup job directories without workspace #
############################################
backup_jobs() { #TODO
  echo "backing up jobs"
  tar cvf ${BACKUP_DIR}/jobs_${NOW}_backup.tar.gz $JENKINS_HOME/jobs/
}

restore_jobs() {
  echo "restoring jobs from $1"
  cp ${BACKUP_DIR}/$1 /
  cd /
  tar xvf $1
  echo "[$(date)] restoring jobs from ${BACKUP_DIR}/$1" > $BACKUP_DIR/history
  chown -R jenkins:nogroup /var/lib/jenkins/jobs
  chown -R jenkins:nogroup /var/lib/jenkins/jobs/*
  echo "DONE"
}

list_backup_jobs() {
  echo "Got following jobs in backup:"
  echo "===================================="
  ls ${BACKUP_DIR}|grep tar.gz
  echo "===================================="
}

################
# usage        #
################
print_usage() {
  echo "-----------------------------------------------------"
  echo -e "usage: ${GREEN}$0 ${NONE}<PARAMETER>"
  echo -e "\n__common parameters_________________________________\n"
  echo -e "${GREEN}  all${NONE} - install all requirements, Jenkins and all plugins"
  echo -e "${GREEN}  download_cli${NONE} - download jenkins-cli.jar for commandline operations"
  echo -e "${GREEN}  install_jenkins${NONE} - install Jenkins only"
  echo -e "${GREEN}  install_prereqs${NONE} - install required software for Jenkins"
  echo -e "${GREEN}  print_usage${NONE} - print this usage info"
  echo -e "${GREEN}  remove_jenkins${NONE} - completely purge Jenkins"
  echo -e "\n__backup/restore parameters_________________________\n"
  echo -e "${GREEN}  backup_current_config${NONE} - make backup of current config.xml"
  echo -e "${GREEN}  list_configs ${NONE} - list config files from backup"
  echo -e "${GREEN}  set_config <config.xml>${NONE} - copy existing config to config.xml"
  echo -e "${GREEN}  backup_jobs${NONE} - backup current jobs folder"
  echo -e "${GREEN}  restore_jobs <job_backup>${NONE} - restore jobs from backup"
  echo -e "${GREEN}  list_backup_jobs${NONE} - list jobs from backup"
  echo "-----------------------------------------------------"
}


############################
# print all global values  #
############################
print_values() {
  echo -e "${GREEN}DEFAULT VALUES _____________________________________"
  echo -e "JENKINS HOME is set to $JENKINS_HOME"
  echo -e "____________________________________________________${NONE}"
}


###########################################################
#  MAIN FUNCTION                                          #
###########################################################

backup_history_preparation


for i in "$@"
do
all) backup_history_preparation
    print_values
    install_prereqs
    install_jenkins
    download_cli
    update_existing_plugins
  ;;
install_prereqs) install_prereqs
  ;;
install_jenkins) install_jenkins
  ;;
download_cli) download_cli
  ;;
remove_jenkins) remove_jenkins
  ;;
list_configs) list_configs
  ;;
set_config) set_config $2  #TODO check if $2 is specified
  ;;
backup_current_config) backup_current_config
  ;;
list_backup_jobs) list_backup_jobs
  ;;
backup_jobs) backup_jobs
  ;;
restore_jobs) restore_jobs $2
  ;;
*) print_usage  
        exit 1
esac
done

exit $?

