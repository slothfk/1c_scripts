#!/bin/sh
#
# 1C Enterprise 8.3 Infobase Attachment Files Backup Script
#
# (c) 2018, Alexey Y. Fedotov
#
# Email: fedotov@kamin.kaluga.ru
#

DIR_BACKUP="<каталог_для_монтирования_сетевого_хранилища>" # Например, /mnt/backup
DIR_REMOTE="<сетевой_диск>" # Например, //server/backup
DIR_SOURCE="<каталог_источник_1> <каталог_источник_2> ... <каталог_источник_N>" # каталоги для синхронизации, записанные через пробел

# В файле /etc/mnt_backup.conf должны хранится учетные данные для подключеник к удаленному серверу
# username=<имя_пользователя>
# password=<пароль_пользователя>

CMD_MOUNT="$(which mount) -t cifs -o credentials=/etc/mnt_backup.conf"
CMD_UMOUNT=$(which umount)

CMD_RSYNC="$(which rsync) -av"

CMD_DATE=$(which date)
DATE_FORMAT="+%b %d %H:%M:%S"

echo "$(${CMD_DATE} "${DATE_FORMAT}") INFO: Infobase Attachment Files Backup Script is started!"

[[ ! -d ${DIR_BACKUP}/files ]] && ${CMD_MOUNT} ${DIR_REMOTE} ${DIR_BACKUP} && \
    echo "$(${CMD_DATE} "${DATE_FORMAT}") INFO: Network share is mount successfuly!"

for DIR_CURRENT in ${DIR_SOURCE}
do
    echo "$(${CMD_DATE} "${DATE_FORMAT}") INFO: Start rsync for ${DIR_CURRENT}"
    ${CMD_RSYNC} ${DIR_CURRENT} ${DIR_BACKUP}/files > /var/log/rsync_${DIR_CURRENT##*/}.log && \
        echo "$(${CMD_DATE} "${DATE_FORMAT}") INFO: rsync for ${DIR_CURRENT} is complete successfuly ($(grep -ce "${DIR_CURRENT##*/}/.*[^/]$" /var/log/rsync_${DIR_CURRENT##*/}.log) files synced)!" || \
        echo "$(${CMD_DATE} "${DATE_FORMAT}") WARNING: Something wrong, when rsync for ${DIR_CURRENT}"
done

${CMD_UMOUNT} ${DIR_BACKUP} && echo "$(${CMD_DATE} "${DATE_FORMAT}") INFO: Network share is unmount successfuly!"

echo "$(${CMD_DATE} "${DATE_FORMAT}") INFO: Infobase Attachment Files Backup Script is complete!"
