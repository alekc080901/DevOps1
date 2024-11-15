#!/bin/bash

if [ "$#" -lt 1 ]; then
  echo "The script must be provided with START|STATUS|STOP command."
  exit 1
fi

if [ "$#" -gt 1 ]; then
  echo "Only one argument must be provided."
  exit 1
fi

ACTION="$1"
DISK_DATA_FILE="./disk_usage_$(date +%Y-%m-%d_%H-%M-%S).csv"

# Запоминание PID между запусками происходит через запись во временный файл и чтение из него. Лучше решения я придумать не смог.
PID_TMP_FILE="/tmp/task_monitor_tmp" 

# Функция запуска мониторинга ресурсов
start_monitor() {
  echo "TIMESTAMP,DISK_USAGE,INODE_USAGE" >> "$DISK_DATA_FILE"
  (while true; do

    # Считывание данных
    TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
    DISK_USAGE=$(df -h / | grep / | awk '{print $5}')
    INODE_USAGE=$(df -i / | grep / | awk '{print $5}')

    # Создание нового файла при изменении даты
    if [ "$(date +%Y-%m-%d)" != "$(echo $DISK_DATA_FILE | cut -d '_' -f 3)" ]; then
      DISK_DATA_FILE="./disk_usage_$(date +%Y-%m-%d_%H-%M-%S).csv"
    fi

    # Запись и пауза
    echo "$TIMESTAMP,$DISK_USAGE,$INODE_USAGE" >> $DISK_DATA_FILE
    sleep 10
  done) &
  MONITOR_PID=$!
  echo $MONITOR_PID > $PID_TMP_FILE
  echo "Monitoring process PID: $MONITOR_PID"
}

# Функция остановки мониторинга ресурсов
stop_monitor() {
  if [ -e $PID_TMP_FILE ]; then
    MONITOR_PID="$(cat $PID_TMP_FILE)" 
  fi

  if [ -z $MONITOR_PID ]; then
    echo "Monitoring process is not running."
    return 1
  fi

  kill $MONITOR_PID
  rm $PID_TMP_FILE
  echo "Monitoring process $MONITOR_PID stopped."
}

# Функция статуса работы процесса сборки ресурсов
check_status() {
  if [ -e $PID_TMP_FILE ]; then
    MONITOR_PID="$(cat $PID_TMP_FILE)" 
  fi

  if [ -z "$MONITOR_PID" ]; then
    echo "Monitoring process is not running."
  else
    echo "Monitoring process is running."
  fi
}

# Perform the action based on the argument
case "$ACTION" in
  START)
  start_monitor
    ;;
  STOP)
    stop_monitor
    ;;
  STATUS)
    check_status
    ;;
  *)
    echo "Incorrect command. Must be: START|STOP|STATUS"
    exit 1
    ;;
esac