#!/bin/bash
#
# 1C Technological Log Compression and Removal Script
#
# (c) 2020, Alexey Y. Fedotov
#
# Email: fedotov@kaminsoft.ru

LOG_DIR="/i40/archive/TLOGS"
ARCH_DATE=$(date -d 'last day' +%y%m%d)

# Remove empty directory
find ${LOG_DIR} -type d -empty -delete

cd ${LOG_DIR}

# Compress and remove last day log files per Nodes
for NODE_NAME in $( find ./ -maxdepth 1 -type d | sed -re 's/^\.\///; s/(.*)\-[^\-]/\1/' | grep -vPe '^$' | sort | uniq ); do
    tar czf ${NODE_NAME}-${ARCH_DATE}.tgz $(find ${NODE_NAME}-*/ -name ${ARCH_DATE}*.log) --remove-files > /dev/null
done

# Remove empty directory after compress
find ${LOG_DIR} -type d -empty -delete

# Remove old files
find ${LOG_DIR} -mtime +90 -delete