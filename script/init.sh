#!/bin/bash

ROOT_DIR=$(cd $(dirname $0)/../../..; pwd)
DB_DIR="$ROOT_DIR/db"
BENCH_DIR="$ROOT_DIR/bench"

export MYSQL_PWD=isucon

mysql -uisucon -e "DROP DATABASE IF EXISTS torb; CREATE DATABASE torb;"
mysql -uisucon torb < "$DB_DIR/schema.sql"

if [ ! -f "$DB_DIR/isucon8q-initial-dataset.sql.gz" ]; then
  echo "Run the following command beforehand." 1>&2
  echo "$ ( cd \"$BENCH_DIR\" && bin/gen-initial-dataset )" 1>&2
  exit 1
fi

mysql -uisucon torb -e 'ALTER TABLE reservations DROP KEY event_id_and_sheet_id_idx'
gzip -dc "$DB_DIR/isucon8q-initial-dataset.sql.gz" | mysql -uisucon torb
mysql -uisucon torb -e 'ALTER TABLE reservations ADD KEY event_id_and_sheet_id_idx (event_id, sheet_id)'
mysql -uisucon torb -e 'ALTER TABLE events ADD reservartion_num_s INTEGER UNSIGNED NOT NULL DEFAULT 0'
mysql -uisucon torb -e 'ALTER TABLE events ADD reservartion_num_a INTEGER UNSIGNED NOT NULL DEFAULT 0'
mysql -uisucon torb -e 'ALTER TABLE events ADD reservartion_num_b INTEGER UNSIGNED NOT NULL DEFAULT 0'
mysql -uisucon torb -e 'ALTER TABLE events ADD reservartion_num_c INTEGER UNSIGNED NOT NULL DEFAULT 0'

tmpfile=$(mktemp)
mysql -uisucon torb -e '
SELECT
    event_id, rank, count(*)
FROM
    reservations r
INNER JOIN
    sheets s
    ON r.sheet_id = s.id
WHERE
    canceled_at IS NULL
GROUP BY event_id, rank
' | sed  -e '1,1d'> tmpfile

cat tmpfile | while read l; do
    id=`echo -n ${l,,} | cut -d" " -f 1`
    rank=`echo -n ${l,,} | cut -d" " -f 2`
    cnt=`echo -n ${l,,} | cut -d" " -f 3`
    mysql -uisucon torb -e "UPDATE events SET reservartion_num_${rank} = $cnt WHERE id = $id"
done
