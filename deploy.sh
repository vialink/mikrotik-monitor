#!/bin/bash

source .env
PREFIX="NEW_"

transfer_file() {
    echo "Transferindo $1"
    ncftp -u $USER -p $PASSWD $HOST <<END_FTP
binary
del $1
put $1
quit
END_FTP
}

run_script() {
    ssh -p $PORT $HOST "/system/script/run $1"
}

import_file() {
    echo "Importando $1"
    ssh -p $PORT $HOST "/system/script/remove $BASENAME"
    ssh -p $PORT $HOST "/import $1"
    ssh -p $PORT $HOST "/file/remove $1"
}

FILES="conf.rsc rc-local-sample.rsc functions.rsc monitoramento-composto.rsc scheduler.rsc"

for f in $FILES; do
    echo "Fazendo deploy de $f"
    BASENAME="${f%%.*}"
    echo "/system/script/add name=$BASENAME source=\"" >"$PREFIX$f"
    sed -e 's:\":\\":g' -e 's:\$:\\$:g' $f >>"$PREFIX$f"
    echo "\"" >>"$PREFIX$f"

    transfer_file $PREFIX$f
    import_file $PREFIX$f
done

run_script "conf"
