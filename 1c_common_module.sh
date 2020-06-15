#!/bin/bash
#
# Эксплуатация 1С Предприятия 8.3: Общий модуль
#
# (c) 2020, Алексей Ю. Федотов
#
# Email: fedotov@kaminsoft.ru
#

INIT_SCRIPT="/etc/init.d/srv1cv83"

source ${INIT_SCRIPT} > /dev/null
[[ -d /etc/sysconfig ]] && source /etc/sysconfig/${INIT_SCRIPT##*/}

[[ -z ${SRV1CV8_DATA} ]] && SRV1CV8_DATA="$(grep ${SRV1CV8_USER} /etc/passwd | cut -f6 -d:)/.1cv8/1C/1cv8" && \
    [[ -f ${SRV1CV8_DATA}/location.cfg ]] && SRV1CV8_DATA="$(awk -F'=' '{print $2}' ${SRV1CV8_DATA}/location.cfg)"


