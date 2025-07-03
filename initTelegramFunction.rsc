:global token
:global chatId
:global srcAddr

:if (0$token = 0) do={set token ""}
:if (0$chatId = 0) do={set chatId ""}
:if (0$srcAddr = 0) do={set srcAddr ""}

:global simbol {""}
:set ($simbol->"Ok") "\E2\9C\85" 
:set ($simbol->"Fail") "\E2\9D\8C"
:set ($simbol->"Warn") "\E2\9A\A0\EF\B8\8F"
:set ($simbol->"Down") "\F0\9F\94\B4"
:set ($simbol->"Up") "\F0\9F\9F\A2"
:set ($simbol->"Unstable") "\F0\9F\9F\A1"
:set ($simbol->"Active") "\F0\9F\94\B5"
:set ($simbol->"Unknown") "\E2\9A\AA"
:set ($simbol->"Waiting") "\E2\8F\B3"
:set ($simbol->"Retry") "\F0\9F\94\81"
:set ($simbol->"Monitoring") "\F0\9F\94\82"
:set ($simbol->"Incident") "\F0\9F\9A\A8"
:set ($simbol->"Boom") "\F0\9F\92\A5"
:set ($simbol->"Bomb") "\F0\9F\92\A3"
:set ($simbol->"Fire") "\F0\9F\94\A5"
:set ($simbol->"Blocked") "\F0\9F\9B\91"
:set ($simbol->"Radio") "\F0\9F\93\A1"
:set ($simbol->"Signal") "\F0\9F\93\B6"
:set ($simbol->"Inet") "\F0\9F\8C\90"
:set ($simbol->"Power") "\F0\9F\94\8C"
:set ($simbol->"Battery") "\F0\9F\94\8E"
:set ($simbol->"BatteryCharging") "\F0\9F\94\8D"
:set ($simbol->"BatteryLow") "\F0\9F\94\8B"
:set ($simbol->"BatteryMedium") "\F0\9F\94\8C"
:set ($simbol->"BatteryHigh") "\F0\9F\94\8D"
:set ($simbol->"BatteryFull") "\F0\9F\94\8E"
:set ($simbol->"LightBulb") "\F0\9F\92\A1"
:set ($simbol->"PointRight") "\F0\9F\91\89"
:set ($simbol->"PointLeft") "\F0\9F\91\88"
:set ($simbol->"PointUp") "\F0\9F\91\86"
:set ($simbol->"PointDown") "\F0\9F\91\87"

:global urlEncode do={
    :local input [:tostr $1]
    :local encoded ""
    :for i from=0 to=([:len $input] - 1) do={
        :local char [:pick $input $i]
        :if ($char = " ") do={ :set char "%20" }
        :if ($char = "!") do={ :set char "%21" }
        :if ($char = "&") do={ :set char "%26" }
        :if ($char = "'") do={ :set char "%27" }
        :if ($char = "(") do={ :set char "%28" }
        :if ($char = ")") do={ :set char "%29" }
        :if ($char = "+") do={ :set char "%2B" }
        :if ($char = ",") do={ :set char "%2C" }
        :if ($char = ":") do={ :set char "%3A" }
        :if ($char = ";") do={ :set char "%3B" }
        :if ($char = "=") do={ :set char "%3D" }
        :if ($char = "?") do={ :set char "%3F" }
        :if ($char = "-") do={ :set char "%2D" }

        # UTF-8 português
        :if ($char = "á") do={ :set char "%C3%A1" }
        :if ($char = "à") do={ :set char "%C3%A0" }
        :if ($char = "é") do={ :set char "%C3%A9" }
        :if ($char = "í") do={ :set char "%C3%AD" }
        :if ($char = "ó") do={ :set char "%C3%B3" }
        :if ($char = "ú") do={ :set char "%C3%BA" }
        :if ($char = "ç") do={ :set char "%C3%A7" }
        :if ($char = "Á") do={ :set char "%C3%81" }
        :if ($char = "À") do={ :set char "%C3%80" }
        :if ($char = "É") do={ :set char "%C3%89" }
        :if ($char = "Í") do={ :set char "%C3%8D" }
        :if ($char = "Ó") do={ :set char "%C3%93" }
        :if ($char = "Ú") do={ :set char "%C3%9A" }
        :if ($char = "Ç") do={ :set char "%C3%87" }

        :set encoded ($encoded . $char)
    }
    :return $encoded
}

:global urlTest do={
    :local destUrl [:tostr $1]
    :global srcAddr
    :put $destUrl
    do {
        :put ("/tool fetch url=$destUrl src-address=$srcAddr keep-result=no mode=https http-method=get")
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
    :put ("Enviando mensagem" . $msg)
    /tool fetch url=("https://api.telegram.org/bot" . $token . "/sendMessage?chat_id=" . $chatId . "&text="  . $msg) keep-result=no
}
