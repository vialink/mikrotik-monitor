#!/bin/bash

source .env

#FILES="initTelegramFunction.rsc monitorarDestinos.rsc relatorioDiario.rsc"
FILES="initTelegramFunction.rsc"

ncftp -u $USER -p $PASSWD $HOST <<END_FTP
binary
mput $FILES
quit
END_FTP

#for f in $FILES; do
#    echo "Fazendo deploy de $f"
#    ssh -p $PORT $HOST "/import $f verbose=yes dry-run"
#    ssh -p $PORT $HOST "/file/remove $f"
#done
