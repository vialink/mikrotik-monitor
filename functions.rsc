:global urlTest do={
    :local destUrl [:tostr $1]
    :global srcAddr
    :put $destUrl
    do {
        /tool fetch url=$destUrl src-address=$srcAddr keep-result=no mode=https http-method=get
    } on-error={
        :return 0
    }
    :return 1
}

:global telegramSend do={
    :local msg [:tostr $1]
    :global token
    :global chatId
    :global simbol
    /tool fetch url=("https://api.telegram.org/bot" . $token . "/sendMessage?chat_id=" . $chatId . "&text="  . $msg) keep-result=no
}