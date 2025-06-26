/system scheduler
add name=monitor interval=5m on-event="system script run monitorarDestinos"
add name=relatorio-daily interval=1d start-time=00:01 on-event="system script run relatorioDiario"

