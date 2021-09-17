This script allows you to run Airflow `backfill` sequentially day by day.
In addition to standart backfill arguments it has `--from-time` `--to-time`.
These arguments limit a day time to run backfill to prevent intersections with a time in wich DAG runs.

Examples:

`./backfill.sh -s 2021-05-01 -e 2021-05-05 --rerun-failed-tasks --delay-on-limit 600 -B --from-time 18:00 --to-time 6:00`

in background:

`nohup ./backfill.sh -s 2021-09-01 -e 2021-10-01 --reset-dagruns -y --delay-on-limit 120 some-dag &> backfill.out &`