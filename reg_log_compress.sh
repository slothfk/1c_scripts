#!/bin/bash
#
# 1C Registration Log Compression and Removal Script
#
# (c) 2018, Alexey Y. Fedotov
#
# Email: fedotov@kamin.kaluga.ru
#
# ======================================================
# WARNINIG: For old style registration log only!
# ======================================================
#

# Find 1C Enterprise 8 service start script
INIT_SCRIPT=`ls /etc/init.d/srv1cv8*`

ARCHIVE_PERIOD=`date +%Y%m%d --date="2 week ago"`
REMOVE_PERIOD=`date +%Y%m%d --date="2 month ago"`

# Use system 1C Enterprise settings
. ${INIT_SCRIPT} > /dev/null
. /etc/sysconfig/${INIT_SCRIPT##*/}

# Get real cluster work directory
[[ ! ${SRV1CV8_DATA} ]] && SRV1CV8_DATA="$(cat /etc/passwd | grep ${SRV1CV8_USER} | cut -f6 -d:)/.1cv8/1C/1cv8" && \
    [[ -f ${SRV1CV8_DATA}/location.cfg ]] && SRV1CV8_DATA=`cat ${SRV1CV8_DATA}/location.cfg | awk -F"=" '{print $2}'`

echo "INFO: 1C Registration Log compression and removal script started!";

# Get real work dir
[[ -f ${SRV1CV8_DATA}/location.cfg ]] && SRV1CV8_DATA=`cat ${SRV1CV8_DATA}/location.cfg | awk -F"=" '{print $2}'`

# TODO: Add -mtime parameter for restrict find result
FILES_TO_COMPRESS=`find ${SRV1CV8_DATA} -name *.lgp | sort`;

for CURRENT_FILE in ${FILES_TO_COMPRESS};
do
    [[ ${CURRENT_FILE##*/} < ${ARCHIVE_PERIOD} ]] && bzip2 ${CURRENT_FILE} && echo "COMPRESS: ${CURRENT_FILE}";
done

# TODO: Add -mtime parameter for restrict find result
FILES_TO_REMOVE=`find ${SRV1CV8_DATA} -name *.bz2 | sort`;

for CURRENT_FILE in ${FILES_TO_REMOVE};
do
    [[ ${CURRENT_FILE##*/} < ${REMOVE_PERIOD} ]] && rm -f ${CURRENT_FILE} && echo "DELETE: ${CURRENT_FILE}";
done

echo "INFO: 1C Registration Log compression and removal script complete!"
