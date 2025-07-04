:global srcAddr "187.45.173.50"
:global minDisponibilidade "0.5"
:global simbol
:global urlTest
:global telegramSend
:global countIcmpGlobalDown 
:global countHttpsGlobalDown 
:global icmpHosts
:global httpsHosts
:local message ""
:local name [/system identity get name]
:local timeDate ([/system clock get time] . " " . [/system clock get date])

:set message "-------------------------------%0A"
:set message ("$message " . $name . " - " . $srcAddr . "%0A" . $timeDate . "%0A")
:set message ($message . "-------------------------------%0A")

if ([typeof $countIcmpGlobalDown] = "nothing") do={
    :set countIcmpGlobalDown 0
}

if ([typeof $countHttpsGlobalDown] = "nothing") do={
    :set countHttpsGlobalDown 0
}

:if ([typeof $icmpHosts] != "array" or [typeof $icmpHosts] = "nothing") do={
    :set icmpHosts [:toarray ""]
    :set icmpHosts  {\
        {"shortName"="registro.br"; "ip"="200.160.2.3"; "downCicles"=0}; \
        {"shortName"="Cloudflare"; "ip"="1.1.1.1"; "downCicles"=0}; \
        {"shortName"="OpenDNS"; "ip"="208.67.222.222"; "downCicles"=0}; \
        {"shortName"="Google"; "ip"="8.8.4.4"; "downCicles"=0}; \
        {"shortName"="Amazon"; "ip"="54.94.33.36"; "downCicles"=0}; \
        {"shortName"="globo.com"; "ip"="186.192.83.12"; "downCicles"=0}; \
        {"shortName"="MaisLink"; "ip"="10.100.10.62"; "downCicles"=0}; \
        {"shortName"="MaisLink"; "ip"="10.100.10.61"; "downCicles"=0} \
    }
}

:if ([typeof $httpsHosts] != "array" or [typeof $httpsHosts] = "nothing") do={
    :set httpsHosts [:toarray ""]
    :set httpsHosts  {\
        {"host"="registro.br"; "downCicles"=0}; \
        {"host"="www.globo.com"; "downCicles"=0}; \
        {"host"="www.uol.com.br"; "downCicles"=0}; \
        {"host"="www.google.com"; "downCicles"=0}; \
        {"host"="www.youtube.com"; "downCicles"=0}; \
        {"host"="www.facebook.com"; "downCicles"=0}; \
        {"host"="www.instagram.com"; "downCicles"=0}; \
        {"host"="www.linkedin.com"; "downCicles"=0}; \
        {"host"="www.whatsapp.com"; "downCicles"=0} \
        {"host"="www.whitehouse.gov"; "downCicles"=0} \
    }
}

:local totalIcmpDown 0
:set message ("$message" . "Testes de icmp%0A")
:for i from=0 to=([:len $icmpHosts] - 1) do={
    :local item ($icmpHosts->$i)
    :local ip ($item->"ip")
    :local dc ($item->"downCicles")
    :local sn ($item->"shortName")

    :local result
    :set result [/ping $ip src-address=$srcAddr count=2 interval=500ms]

    :if ($result = 0) do={
        :set totalIcmpDown ($totalIcmpDown + 1)
        :set dc ($dc + 1)
        :set message ("$message" . "    " . $simbol->"Offline" . $ip . " (" . $sn . ")" . " - " . $dc . " ciclo(s). %0A")
    } else={
        :set message ("$message" . "    " . $simbol->"Online" . $ip . " (" . $sn . ")" . "%0A")
        :set dc 0
    }
    # Atualiza o item no array
    :set ($icmpHosts->$i) {"shortName"=$sn; "ip"=$ip; "downCicles"=$dc}
}
:set message ($message . "%0A")

:local totalHttpsDown 0
:set message ("$message" . "Testes de https%0A")
:for i from=0 to=([:len $httpsHosts] - 1) do={
    :local item ($httpsHosts->$i)
    :local host ($item->"host")
    :local dc ($item->"downCicles")

    :local url ("https://" . $host)

    :do {
        :local result
        :set result [$urlTest $url]
        if ($result = 0) do={
            :set totalHttpsDown ($totalHttpsDown + 1)
            :set dc ($dc + 1)
            :set message ("$message" . "    " . $simbol->"Offline" . $host . " - " . $dc . " ciclo(s). %0A")
        } else={
            :set message ("$message" . "    " . $simbol->"Online" . $host . "%0A")
            :set dc 0
        }
    } on-error={
        :put ("Erro ao testar " $url)
    }
    # Atualiza o item no array
    :set ($httpsHosts->$i) {"host"=$host; "downCicles"=$dc}
}
:set message ($message . "%0A%0A")

:local disponibilidadeIcmp (1 - ($totalIcmpDown / [:len $icmpHosts]))

:if ($disponibilidadeIcmp < $minDisponibilidade) do={
    :set countIcmpGlobalDown ($countIcmpGlobalDown + 1)
    :set message ($message . $simbol->"PointRight" . " " . $simbol->"Fail" . " Global icmp fail " . $simbol->"PointLeft" . "%0A")
} else={
    :set message ($message . $simbol->"PointRight" . " " . $simbol->"Ok" . " Global icmp ok " . $simbol->"PointLeft" . "%0A")
    :set countIcmpGlobalDown 0
}

:local disponibilidadeHttps (1 - ($totalHttpsDown / [:len $httpsHosts]))

:if ($disponibilidadeHttps < $minDisponibilidade) do={
    :set countHttpsGlobalDown ($countHttpsGlobalDown + 1)
    :set message ($message . $simbol->"PointRight" . " " . $simbol->"Fail" . " Global https fail " . $simbol->"PointLeft" . "%0A")
} else={
    :set message ($message . $simbol->"PointRight" . " " . $simbol->"Ok" . " Global https ok " . $simbol->"PointLeft" . "%0A")
    :set countHttpsGlobalDown 0
}

$telegramSend ($message)