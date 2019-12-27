#!/bin/bash
#
# 1C Enterprise 8.3 Terminate User Sessions via RAC
#
# (c) 2019, Alexey Y. Fedotov
#
# Email: fedotov@kaminsoft.ru
#

PATH=${PATH}:$(ls -d /opt/1C/v8*/[xi]* | tail -n1)

function parse_parameters {
    while [[ $1 ]] ; do
        case $1 in
        -s) SRV_NAME=$2; shift 2;;
        -p) SRV_PORT=$2; shift 2;;
        -l) SESS_LIST=$2; shift 2;;
        -u) ADM_USER=$2; shift 2;;
        -w) ADM_PASS=$2; shift 2;;
        *) shift;;
        esac;
    done
    check_parameters;
}

function check_parameters {

    [[ -z ${SRV_NAME} ]] && SRV_NAME=$(hostname -s);

    [[ -z ${SRV_PORT} ]] && SRV_PORT=1545;

    [[ -z ${SESS_LIST} ]] && echo "ОШИБКА: Не указаны номера сессий, которые необходимо завершить!" && exit 1;

}

parse_parameters ${@};

CLSTR_UUID=$( rac cluster list ${SRV_NAME}:${SRV_PORT} | grep cluster | \
        perl -pe 's/[ "]//g; s/^cluster:(.*)/\1/' )

for CURR_CLSTR in ${CLSTR_UUID} 
do
    ACT_SESS+=( $(rac session list --cluster ${CURR_CLSTR} ${SRV_NAME}:${SRV_PORT} | grep -B1 -Pe "session-id\s+:\s+(${SESS_LIST//,/|})" | \
        perl -pe "s/^-+\n//; s/[ \"]//g; s/^session:(.*)\n/${CURR_CLSTR}:\1/; s/.*-id(:.*)/\1/") ) 
done

[[ $(echo ${SESS_LIST//,/ } | wc -w) -lt ${#ACT_SESS[*]} ]] && echo "ОШИБКА: количество обнаруженных сеансов превышает число заданных для завершения!" && exit 1

for CURR_SESS in ${SESS_LIST//,/ }
do
    echo -n "Сеанс номер ${CURR_SESS}: "
    SESS_UUID=$(echo ${ACT_SESS[*]} | grep -Pe "([\w\d\-]+):${CURR_SESS}\b" | perl -pe "s/.*(\s|^)([\w\d\-]+:[\w\d\-]+):${CURR_SESS}\b.*/\2/")
    if [[ -z ${SESS_UUID} ]]; then
        echo "не найден!"
    else
        rac session terminate --cluster ${SESS_UUID%:*} --session ${SESS_UUID#*:} ${SRV_NAME}:${SRV_PORT} && \
            echo "успешно завершен!" || echo "завершить не удалось!"
    fi
done

