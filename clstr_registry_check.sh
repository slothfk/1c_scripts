#!/bin/bash
#
# 1C Enterprise 8.3 Cluster Registry Check and Backup Script
#
# (c) 2018, Alexey Y. Fedotov
#
# Email: fedotov@kamin.kaluga.ru
#

INIT_SCRIPT=`ls /etc/init.d/srv1cv8*`

# Use system 1C Enterprise settings
. ${INIT_SCRIPT} > /dev/null
. /etc/sysconfig/${INIT_SCRIPT##*/}

# Get real cluster work directory
[[ ! ${SRV1CV8_DATA} ]] && SRV1CV8_DATA="/home/${SRV1CV8_USER}/.1cv8/1C/1cv8" && \
    [[ -f ${SRV1CV8_DATA}/location.cfg ]] && SRV1CV8_DATA=`cat ${SRV1CV8_DATA}/location.cfg | awk -F"=" '{print $2}'`

# Find all clusters in work directory
RMNGR_PORTS=`find ${SRV1CV8_DATA} -name reg_* -printf %f | sed -r 's/reg_/ /g'`

BACKUP_DIR="/home/backup"	# Backup directory
CACHE_DIR="/var/tmp/1C"		# Cache directory
REG_FILE="1CV8Clst.lst"		# Cluster registry file name
MAX_CPS=30 			# Maximum number of changes per second

# Check cache directory existance
[[ ! -d ${CACHE_DIR} ]] && mkdir ${CACHE_DIR}

for CURR_PORT in $RMNGR_PORTS
do

    CURR_CHECKSUM=""

    [[ -f ${SRV1CV8_DATA}/reg_${CURR_PORT}/${REG_FILE} ]] && \
        CURR_CHECKSUM=`md5sum ${SRV1CV8_DATA}/reg_${CURR_PORT}/${REG_FILE} | awk '{print $1}'` && \
        CURR_VERSION=`grep "}$" ${SRV1CV8_DATA}/reg_${CURR_PORT}/${REG_FILE} | sed -r 's/.*,([0-9]*)\}$/\1/'` || \
        echo "ERROR: Current cluster registy (port ${CURR_PORT}) not found!"

    [[ ! ${CURR_CHECKSUM} ]] && continue

    [[ -f ${SRV1CV8_DATA}/reg_${CURR_PORT}/1CV8Clsto.lst ]] && \
        OLD_CHECKSUM=`md5sum ${SRV1CV8_DATA}/reg_${CURR_PORT}/1CV8Clsto.lst | awk '{print $1}'` && \
        OLD_VERSION=`grep "}$" ${SRV1CV8_DATA}/reg_${CURR_PORT}/1CV8Clsto.lst | sed -r 's/.*,([0-9]*)\}$/\1/'`

    [[ ! -f ${CACHE_DIR}/clstr_reg_${CURR_PORT}.hash ]] && echo ${CURR_VERSION}:${CURR_CHECKSUM} > ${CACHE_DIR}/clstr_reg_${CURR_PORT}.hash

    CACHE_HASH=($(cat ${CACHE_DIR}/clstr_reg_${CURR_PORT}.hash | sed 's/:/ /'))

    if ([ ${CACHE_HASH[1]} != ${CURR_CHECKSUM} ]); then
        echo "INFO: Cluster registry (port ${CURR_PORT}) is changed!"

        DIFF_VERSION=$((${CURR_VERSION}-${CACHE_HASH[0]}))

        if ([ ${DIFF_VERSION} -gt 0 ] && [ ${DIFF_VERSION} -le ${MAX_CPS} ]); then
            echo "${CURR_VERSION}:${CURR_CHECKSUM}" > ${CACHE_DIR}/clstr_reg_${CURR_PORT}.hash

            [[ $((${CURR_VERSION}-1)) -eq ${OLD_VERSION} ]] && \
                zip ${BACKUP_DIR}/${REG_FILE%.*}.zip ${SRV1CV8_DATA}/reg_${CURR_PORT}/${REG_FILE} > /dev/null && \
                echo "INFO: Current cluster registry (port ${CURR_PORT}) is backuped succesful!" || \
                echo "WARNING: Something wrong, old and current cluster registry version (port ${CURR_PORT}) not synced!"

            [[ ${DIFF_VERSION} -gt 1 ]] && echo "WARNING: Cluster registry (port ${CURR_PORT}) is changed more then one time (${DIFF_VERSION}) at period of control!"
        else
            echo "ERROR: Invalid version of current cluster registry (port ${CURR_PORT})!";
            [[ ${CACHE_HASH[0]} -eq ${OLD_VERSION} &&  ${CACHE_HASH[1]} -eq ${OLD_CHECKSUM} ]] && echo "INFO: Version of old cluster registry (port ${CURR_PORT}) is valid!";
        fi

    fi

done

