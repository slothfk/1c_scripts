#!/bin/bash
#
# 1C Enterprise 8.3 Platform Packages Remote Install
#
# (c) 2019, Alexey Y. Fedotov
#
# Email: fedotov@kaminsoft.ru
#


SERVER_LIST="<файл списка серверов>"

SSH_USER="<пользователь ssh>"
SMB_USER="<пользователь сетевого ресурса>"
SMB_PASS="<пароль пользователя сетевого ресурса>"
SMB_SHARE="<сетевой ресурс с пакетами 1С Предприятия>"

WEB_PKG_LIST="common server ws"
APP_PKG_LIST="common server"
TS_PKG_LIST="common server client"

TEMP_DIR="temp_dir"

HTTPD="httpd" # Имя сервиса для web-сервера
SRV1CV8="srv1cv83" # Имя сервиса для сервера 1С Предприятия
RAS1CV8="ras" # Имя сервиса для RAS

SERVERS_LIST=$(while read SERVER_NAME SERVER_FUNC ; do
    echo "${SERVERS_LIST}${SERVER_NAME}|${SERVER_FUNC} ";
done < ${SERVER_LIST})

#echo ${SERVERS_LIST}; exit 1;

[[ ${1} == "test" ]] && TEST_MODE=1 || TEST_MODE=0

function print_status {
    echo -en \\033[60G
    case $1 in
        0) echo "[  OK  ]";;
        *) echo "[FAILED]";;
    esac
}

function service_control {
    [[ $2 == "start" ]] && echo -n " * Запуск" || echo -n " * Останов" ;
    case $1 in
        ${HTTPD}) echo -n " web-сервера" ;;
        ${SRV1CV8}) echo -n " сервера 1С Предприятия";;
        ${RAS1CV8}) echo -n " RAS 1С Предприятия";;
    esac
    echo -n " на ${3}: "; 
    [[ ${TEST_MODE} == 0 ]] && ssh ${SSH_USER}@${3} "sudo systemctl $2 $1"; print_status $?;
}

echo "====================================================================="
echo "=            Скрипт обновления платформы 1С Предприятия             ="
echo "====================================================================="

echo "Версии платформы, доступные для установки:"
[[ ! -d ${TEMP_DIR} ]] && mkdir ${TEMP_DIR};
sudo mount -t cifs -o username=${SMB_USER},password=${SMB_PASS} ${SMB_SHARE} ${TEMP_DIR};
VERSIONS_LIST=$(ls ${TEMP_DIR}); VERSION_COUNT=1;
for CURRENT in ${VERSIONS_LIST};
do
    echo "(${VERSION_COUNT}) $CURRENT";
    VERSION_COUNT=$((${VERSION_COUNT}+1));
done
while [[ -z ${INSTALL_VERSION} ]]; do
    echo -n "Выберите версию платформы для установки (по умолчанию 1): "
    read INSTALL_VERSION;

    [[ -z ${INSTALL_VERSION} ]] && INSTALL_VERSION=1

    INSTALL_VERSION=$(echo $VERSIONS_LIST | cut -f${INSTALL_VERSION} -d" ")
    [[ -z ${INSTALL_VERSION} ]] && echo "Плохой выбор, попробуйте еще раз!"
done

for PKG in ${WEB_PKG_LIST}; do WEB_RPMS_LIST="${WEB_RPMS_LIST}$(find ${TEMP_DIR}/${INSTALL_VERSION}/RPMS/ -name *83-$PKG*) "; done;
for PKG in ${APP_PKG_LIST}; do APP_RPMS_LIST="${APP_RPMS_LIST}$(find ${TEMP_DIR}/${INSTALL_VERSION}/RPMS/ -name *83-$PKG*) "; done;
for PKG in ${TS_PKG_LIST}; do TS_RPMS_LIST="${TS_RPMS_LIST}$(find ${TEMP_DIR}/${INSTALL_VERSION}/RPMS/ -name *83-$PKG*) "; done;

sudo umount ${TEMP_DIR};
rmdir ${TEMP_DIR};

echo "====================================================================="
echo "ВНИМАНИЕ! Для установки выбрана версия платформы ${INSTALL_VERSION}!"
echo "Для продолжения нажмите ENTER или Ctrl-C чтобы прервать работу скрипта!"
read


echo "====================================================================="
echo "=       Начало выполнения обновления платформы 1С Предприятия       ="
echo "====================================================================="
echo "Останавливаем web-сервера:"
for CURR_SERVER in ${SERVERS_LIST}; do
    [[ ${CURR_SERVER##*|} == "web" ]] && service_control ${HTTPD} stop ${CURR_SERVER%%|*};
done

echo "Останавливаем сервера 1С Предприятия:"
for CURR_SERVER in ${SERVERS_LIST}; do
    if [[ ${CURR_SERVER##*|} == "application" ]] ; then
        service_control ${SRV1CV8} stop ${CURR_SERVER%%|*};
        service_control ${RAS1CV8} stop ${CURR_SERVER%%|*};
    fi
done

echo "Устанавливаем пакеты 1С Предприятия:"
for CURR_SERVER in ${SERVERS_LIST}; do
    echo -n " * Создаем временный каталог на ${CURR_SERVER%%|*}";
    [[ ${TEST_MODE} == 0 ]] && ssh ${SSH_USER}@${CURR_SERVER%%|*} "[[ ! -d ${TEMP_DIR} ]] && mkdir ${TEMP_DIR}" ; print_status $?;
    echo -n " * Монтируем сетевой ресурс на ${CURR_SERVER%%|*}"
    [[ ${TEST_MODE} == 0 ]] && ssh ${SSH_USER}@${CURR_SERVER%%|*} "sudo mount -t cifs -o username=${SMB_USER},password=${SMB_PASS} ${SMB_SHARE} ${TEMP_DIR}" ; print_status $?;

    #ssh ${SSH_USER}@${CURR_SERVER%%|*} "[[ ! -d ${TEMP_DIR}/${INSTALL_VERSION}/RPMS ]]" && ssh ${SSH_USER}@${CURR_SERVER%%|*} "mkdir ${TEMP_DIR}/${INSTALL_VERSION}/RPMS" && \
    #    ssh ${SSH_USER}@${CURR_SERVER%%|*} "for CUR_FILE in ${TEMP_DIR}/${INSTALL_VERSION}/*.tar.gz; do tar xzf ${CUR_FILE} -C ${TEMP_DIR}/${INSTALL_VERSION}/RPMS/; done";

    echo -n " * Удаляем старые версии пакетов на ${CURR_SERVER%%|*}: ";
    [[ ${TEST_MODE} == 0 ]] && ssh ${SSH_USER}@${CURR_SERVER%%|*} "sudo yum -y -q remove 1C_Enterprise83* 2>/dev/null"; print_status $?;
    echo -n " * Устанавливаем новые версии пакетов на ${CURR_SERVER%%|*}: "
    case ${CURR_SERVER##*|} in
        terminal) RPMS_LIST=${TS_RPMS_LIST};;
        web) RPMS_LIST=${WEB_RPMS_LIST};;
        application) RPMS_LIST=${APP_RPMS_LIST};;
    esac
    INSTALL_CMD="sudo yum -y -q install ${RPMS_LIST}"
    [[ ${TEST_MODE} == 0 ]] && ssh ${SSH_USER}@${CURR_SERVER%%|*} ${INSTALL_CMD} ; print_status $?;

    echo -n " * Отмонтируем сетевой ресурс на ${CURR_SERVER%%|*}"
    [[ ${TEST_MODE} == 0 ]] && ssh ${SSH_USER}@${CURR_SERVER%%|*} "sudo umount ${TEMP_DIR}" ; print_status $?;
    echo -n " * Удаляем временный каталог на ${CURR_SERVER%%|*}";
    [[ ${TEST_MODE} == 0 ]] && ssh ${SSH_USER}@${CURR_SERVER%%|*} "rmdir temp_dir" ; print_status $?;
done

echo "Запускаем сервера 1С Предприятия:"
for CURR_SERVER in ${SERVERS_LIST}; do
    if [[ ${CURR_SERVER##*|} == "application" ]]; then
        service_control ${SRV1CV8} start ${CURR_SERVER%%|*};
        service_control ${RAS1CV8} start ${CURR_SERVER%%|*};
    fi
done

echo "Запускаем web-сервера:"
for CURR_SERVER in ${SERVERS_LIST}; do
    [[ ${CURR_SERVER##*|} == "web" ]] && service_control ${HTTPD} start ${CURR_SERVER%%|*};
done

echo "====================================================================="
echo "=           Обновление платформы 1С Предприятия завершено           ="
echo "====================================================================="

echo ""
echo "ВНИМАНИЕ! Не забудьте изменить настройки версии платформы в"
echo "          Менеджере сервиса!"
echo ""
