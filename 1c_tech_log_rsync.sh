#!/bin/bash
#
# Эксплуатация 1С Предприятия 8.3: Копирование фалов ТЖ
#
# (c) 2020, Алексей Ю. Федотов
#
# Email: fedotov@kaminsoft.ru
#

LOG_DIR="/var/log/1C/"
ARCH_DIR="/iRR/archive/tech_logs"

rsync -az ${LOG_DIR} ${ARCH_DIR}/$(hostname -s)
