#!/bin/bash
#
# Эксплуатация 1С Предприятия 8.3: Сжатие и удаление файлов ТЖ
#
# (c) 2020, Алексей Ю. Федотов
#
# Email: fedotov@kaminsoft.ru
#

ARCH_DIR="/iRR/archive/tech_logs"

cd ${ARCH_DIR}

# Compress and remove log files most then one day oldest per Nodes
for NODE_NAME in $( find ./ -maxdepth 1 -type d | sed -re 's/^\.\///; s/(.*)\-[^\-]+/\1/' | grep -vPe '^$' | sort | uniq ); do
    for ARCH_DATE in $(find ./${NODE_NAME}* -mtime +1 -daystart -name *.log -printf "%f\n" |  sed -re "s/(^[0-9]{6}).*/\1/" | sort | uniq); do
        tar czf ${NODE_NAME}-${ARCH_DATE}.tgz --remove-files $(find ${NODE_NAME}*/ -name ${ARCH_DATE}*.log) > /dev/null
        touch ${NODE_NAME}-${ARCH_DATE}.tgz -t $(date -d "${ARCH_DATE} next day" +%m%d%H%M)
    done
done

# Удаление файлов старше 90 дней
find ${ARCH_DIR} -mtime +90 -name *.tgz -type f -daystart -delete

# Удаление пустых каталогов
find ${ARCH_DIR} -type d -empty -delete
