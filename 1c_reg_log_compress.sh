#!/bin/bash
#
# Эксплуатация 1С Предприятия 8.3: Сжатие и удаление файлов ЖР
#
# (c) 2020, Алексей Ю. Федотов
#
# Email: fedotov@kaminsoft.ru
#
# ======================================================
# ВНИМАНИЕ: Использовать только для ЖР в старом формате
# ======================================================
#

# Find 1C Enterprise 8 service start script
INIT_SCRIPT=$(ls /etc/init.d/srv1cv8*)

ARCHIVE_PERIOD=$(date +%Y%m%d --date='2 week ago')
REMOVE_PERIOD=$(date +%Y%m%d --date='2 month ago')

# Use system 1C Enterprise settings
source ${INIT_SCRIPT} > /dev/null
[[ -d /etc/sysconfig ]] && source /etc/sysconfig/${INIT_SCRIPT##*/}

# Get real cluster work directory
[[ -z ${SRV1CV8_DATA} ]] && SRV1CV8_DATA="$(cat /etc/passwd | grep ${SRV1CV8_USER} | cut -f6 -d:)/.1cv8/1C/1cv8"

# Get real work dir
[[ -f ${SRV1CV8_DATA}/location.cfg ]] && SRV1CV8_DATA=$(cat ${SRV1CV8_DATA}/location.cfg | awk -F"=" '{print $2}')

# TODO: Add -mtime parameter for restrict find result
FILES_TO_COMPRESS=$(find ${SRV1CV8_DATA} -name '*.lgp' | sort)

DEL_FILES=0; ARCH_FILES=0

for CURRENT_FILE in ${FILES_TO_COMPRESS}; do
    if [[ ${CURRENT_FILE##*/} < ${REMOVE_PERIOD} ]]; then
        rm -f ${CURRENT_FILE} && (( DEL_FILES+=1 ))
    elif [[ ${CURRENT_FILE##*/} < ${ARCHIVE_PERIOD} ]]; then
        bzip2 ${CURRENT_FILE} && (( ARCH_FILES+=1 ))
    fi
done

# TODO: Add -mtime parameter for restrict find result
FILES_TO_REMOVE=$(find ${SRV1CV8_DATA} -name '*.bz2' | sort)

for CURRENT_FILE in ${FILES_TO_REMOVE}; do
    [[ ${CURRENT_FILE##*/} < ${REMOVE_PERIOD} ]] && rm -f ${CURRENT_FILE} && (( DEL_FILES+=1 ))
done

[[ ${ARCH_FILES} -gt 0 ]] && echo "Количество сжатых файлов ЖР: ${ARCH_FILES}"
[[ ${DEL_FILES} -gt 0 ]] && echo "Количество удаленных файлов ЖР: ${DEL_FILES}"
