#!/bin/bash
#
# Эксплуатация 1С Предприятия 8.3: Сохранение файлов реестра кластера
#
# (c) 2020, Алексей Ю. Федотов
#
# Email: fedotov@kaminsoft.ru
#

BACKUP_DIR="/iRR/archive/clusters"
HOSTNAME=$(hostname -s)
DATETIME=$(date +%y%m%d%H%M)

[[ -f ${0%/*}/1c_common_module.sh ]] && source ${0%/*}/1c_common_module.sh

cd ${SRV1CV8_DATA} &>/dev/null || exit 1

[[ -d ${BACKUP_DIR} ]] || exit 1
[[ -d ${BACKUP_DIR}/${HOSTNAME} ]] || mkdir ${BACKUP_DIR}/${HOSTNAME}

FILES_TO_BACKUP=$(find ./ -name '1*8*.lst')

for CURRENT_FILE in ${FILES_TO_BACKUP}; do
    [[ $(grep -o "{" ${CURRENT_FILE} | wc -l) -eq $(grep -o "}" ${CURRENT_FILE} | wc -l) ]] &&
        tar rf ${BACKUP_DIR}/${HOSTNAME}/${DATETIME}.tar ${CURRENT_FILE} || \
        echo "ОШИБКА: Файл ${CURRENT_FILE} не прошел проверку!"
done

[[ -f ${BACKUP_DIR}/${HOSTNAME}/$DATETIME.tar ]] && gzip ${BACKUP_DIR}/${HOSTNAME}/$DATETIME.tar

find ${BACKUP_DIR}/${HOSTNAME}/ -name '*.gz' -mtime +7 -daystart -delete
