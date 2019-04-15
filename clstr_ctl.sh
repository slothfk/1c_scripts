#!/bin/bash
#
# 1C Enterprise 8.3 Cluster Control Script
#
# (c), 2019, Alexey Y. Fedotov
#
# Email: fedotov@kaminsoft.ru
#

USER_NAME="usr1cv8";
SERVICE_1C="srv1cv83";

function print_status {
    echo -en \\033[60G
    case $1 in
        0) echo "[ DONE ]";;
        *) echo "[FAILED]";;
    esac
}

function parse_parameters {
    while [[ $1 ]] ; do
        case $1 in
        -f) LIST_FILE=$2; shift 2;;
        -u) USER_NAME=$2; shift 2;;
        -s) SERVICE_1C=$2; shift 2;;
        (start|stop|restart)
            CMD_NAME=$1; shift;
            if [[ ${1:0:1} != "-" ]]; then
                SRV_NAME=${1%%:*};
                SRV_PORT=${1##*:};
                shift;
            fi;;
        *) shift;;
        esac;
    done
    check_parameters;
}

function check_parameters {

    [[ -z ${CMD_NAME} || ( -z ${SRV_NAME} && -z ${LIST_FILE} ) ]] && echo "ОШИБКА: Не указаны необходмые параметры!" && exit 1;

    [[ -z ${SRV_NAME} && ! -s ${LIST_FILE} ]] && echo "ОШИБКА: Указанный файл списка серверов не существует или имеет нулевой размер!" && exit 1;

    [[ -n ${SRV_NAME} && ${CMD_NAME} == "start" && ! -s ${SRV_NAME}.stoped ]] && echo "ОШИБКА: Указанный кластер серверов не был остановлен с помощью данного скрипта!" && exit 1;

    [[ -n ${SRV_NAME} && ( ${CMD_NAME} == "stop" || ${CMD_NAME} == "restart" ) && -s ${SRV_NAME}.stoped ]] && echo "ОШИБКА: Указанный кластер серверов уже остановлен с помощью данного скрипта!" && exit 1;

}

function clstr_command {

    if [[ -n ${SRV_NAME} && ${1} == "stop" ]]; then
        SRV_LIST_CMD="G_VER_ARCH=$(grep -m 1 -oP '^G_VER_ARCH=\K(.+)' /etc/init.d/srv1cv83);\
            /opt/1C/v8.3/\${G_VER_ARCH}/rac server list --cluster=\$(/opt/1C/v8.3/\${G_VER_ARCH}/rac cluster list ${SRV_NAME}:${SRV_PORT} 2>/dev/null |\
             grep -m 1 -oP '^cluster\s+:\s\K(.+)') ${SRV_NAME}:${SRV_PORT} 2>/dev/null | tr -d [\ ] |\
             grep -oP '((using)|(agent-host:))\K(.+)' | perl -pe '\$_=~s/(^[^:].+)\n/\1/'"

        SRV_LIST=$(ssh ${USER_NAME}@${SRV_NAME} "${SRV_LIST_CMD}");
    else
        SRV_LIST=$(cat ${SRV_NAME}.stoped);
        rm -f ${SRV_NAME}.stoped;
    fi

    [[ -z ${SRV_LIST} ]] && echo "ОШИБКА: Пустой список серверов кластера!" && exit 1;

    for CUR_SRV in ${SRV_LIST}; do
        if [[ ${1} == "start" || ${1} == "stop" ]]; then
            case ${1} in
            start) echo -n "Запуск";;
            stop) echo -n "Останов";;
            esac
            echo -n " сервера 1С Предприятия на ${CUR_SRV%:*}:"
            ssh ${USER_NAME}@${CUR_SRV%:*} "sudo systemctl ${CMD_NAME} ${SERVICE_1C}";
            SSH_RESULT=$?;
            print_status $SSH_RESULT;
            [[ ${1} == "stop" && ${SSH_RESULT} == 0 ]] && echo ${CUR_SRV} >> ${SRV_NAME}.stoped;
            [[ ${1} == "start" && ${SSH_RESULT} != 0 ]] && echo ${CUR_SRV} >> ${SRV_NAME}.stoped;
        fi
    done
}

parse_parameters $@;

if [[ $CMD_NAME == "restart" ]]; then
    clstr_command stop;
    clstr_command start;
else
    clstr_command $CMD_NAME;
fi