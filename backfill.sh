#!/bin/bash

POSITIONAL=()
START_TIME="00:00"
END_TIME=$START_TIME

while [ $# -gt 0 ]; do
  key="$1"

  case $key in
  -s)
    START_DATE="$2"
    shift # past argument
    shift # past value
    ;;
  -e)
    END_DATE="$2"
    shift # past argument
    shift # past value
    ;;
  --from-time)
    START_TIME="$2"
    shift # past argument
    shift # past value
    ;;
  --to-time)
    END_TIME="$2"
    shift # past argument
    shift # past value
    ;;
  -B|--run-backwards)
    RUN_BACKWARDS=True
    shift # past argument
    ;;
  *)                   # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift              # past argument
    ;;
  esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

DATES=()
while ! [ "$START_DATE" \> "$END_DATE" ]; do
  DATES+=($START_DATE)
  START_DATE=$(date -d "$START_DATE + 1 day" +%F)
done

if [ $RUN_BACKWARDS ]; then
  export IFS=$'\n'
  DATES=($(sort -r <<< "${DATES[*]}"))
  unset IFS
fi

AIRFLOW_POD=$(kubectl get pods -n airflow | grep web | grep Running | head -n1 | awk '{print $1;}')

for dt in "${DATES[@]}"; do
  while ! { [ $END_TIME = $START_TIME ] || { [ $END_TIME \> $START_TIME ] && [ $(date '+%H:%M') \> $START_TIME -o $(date '+%H:%M') = $START_TIME ] && [ $(date '+%H:%M') \< $END_TIME -o $(date '+%H:%M') = $END_TIME ]; } || { [ "$END_TIME" \< "$START_TIME" ] && { [ "$(date '+%H:%M')" \> "$START_TIME" ] || [ "$(date '+%H:%M')" = "$START_TIME" ] || [ "$(date '+%H:%M')" \< "$END_TIME" ] || [ "$(date '+%H:%M')" = "$END_TIME" ]; }; }; }; do
     sleep 1m
  done
  command="kubectl exec -it -n airflow "$AIRFLOW_POD" -- airflow backfill -s "$dt" -e "$(date -d "${dt} + 1 day" "+%Y-%m-%d")" "$(if [ $RUN_BACKWARDS ]; then echo "-B"; fi)" "${POSITIONAL[@]}""
  echo $command
  $command
done