/system/script/run conf
/system/script/run rc-local

:global minAvailability
:global simbol
:global urlTest
:global telegramSend
:global countIcmpGlobalDown 
:global countHttpsGlobalDown 
:global icmpHosts
:global httpsHosts
:global sendMessage
:global srcAddr

:local message ""
:local name [/system identity get name]
:local timeDate ([/system clock get time] . " " . [/system clock get date])

:set message "-------------------------------%0A"
:set message ($message . $name . " - " . $srcAddr . "%0A" . $timeDate . "%0A")
:set message ($message . "-------------------------------%0A")

if ([typeof $countIcmpGlobalDown] = "nothing") do={
    :set countIcmpGlobalDown 0
}

if ([typeof $countHttpsGlobalDown] = "nothing") do={
    :set countHttpsGlobalDown 0
}

:local totalIcmpDown 0
:set message ($message . "Icmp testing%0A")
:for i from=0 to=([:len $icmpHosts] - 1) do={
    :local item ($icmpHosts->$i)
    :local ip ($item->"ip")
    :local dc ($item->"downCicles")
    :local sn ($item->"shortName")

    :local result
    :set result [/ping $ip src-address=$srcAddr count=2 interval=500ms]

    :if ((($result = 0) && ($dc = 0)) || (($result != 0) && ($dc >= 1))) do={
        :set sendMessage 1
    }

    :if ($result = 0) do={
        :set totalIcmpDown ($totalIcmpDown + 1)
        :set dc ($dc + 1)
        :set message ($message . "    " . $simbol->"Offline" . $ip . " (" . $sn . ")" . " - " . $dc . " ciclo(s). %0A")
    } else={
        :set message ($message . "    " . $simbol->"Online" . $ip . " (" . $sn . ")" . "%0A")
        :set dc 0
    }
    :set ($icmpHosts->$i) {"shortName"=$sn; "ip"=$ip; "downCicles"=$dc}
}
:set message ($message . "%0A")

:local totalHttpsDown 0
:set message ($message . "Https testing%0A")
:for i from=0 to=([:len $httpsHosts] - 1) do={
    :local item ($httpsHosts->$i)
    :local host ($item->"host")
    :local dc ($item->"downCicles")
    :put ("host:" . $host . " dc: " . $dc)

    :local url ("https://" . $host)

    :do {
        :local result
        :set result [$urlTest $url]
        :if ((($result = 0) && ($dc = 0)) || (($result != 0) && ($dc >= 1))) do={
            :set sendMessage 1
        }
        :if ($result = 0) do={
            :set totalHttpsDown ($totalHttpsDown + 1)
            :set dc ($dc + 1)
            :set message ($message . "    " . $simbol->"Offline" . $host . " - " . $dc . " ciclo(s). %0A")
        } else={
            :set message ($message . "    " . $simbol->"Online" . $host . "%0A")
            :set dc 0
        }
    } on-error={
        :put ("Error testing " $url)
    }
    :set ($httpsHosts->$i) {"host"=$host; "downCicles"=$dc}
}
:set message ($message . "%0A%0A")

:local disponibilidadeIcmp (1 - ($totalIcmpDown / [:len $icmpHosts]))

:if ($disponibilidadeIcmp < $minAvailability) do={
    :set countIcmpGlobalDown ($countIcmpGlobalDown + 1)
    :set message ($message . $simbol->"PointRight" . " " . $simbol->"Fail" . " Global icmp fail " . $simbol->"PointLeft" . "%0A")
} else={
    :set message ($message . $simbol->"PointRight" . " " . $simbol->"Ok" . " Global icmp ok " . $simbol->"PointLeft" . "%0A")
    :set countIcmpGlobalDown 0
}

:local disponibilidadeHttps (1 - ($totalHttpsDown / [:len $httpsHosts]))

:if ($disponibilidadeHttps < $minAvailability) do={
    :set countHttpsGlobalDown ($countHttpsGlobalDown + 1)
    :set message ($message . $simbol->"PointRight" . " " . $simbol->"Fail" . " Global https fail " . $simbol->"PointLeft" . "%0A")
} else={
    :set message ($message . $simbol->"PointRight" . " " . $simbol->"Ok" . " Global https ok " . $simbol->"PointLeft" . "%0A")
    :set countHttpsGlobalDown 0
}

if ($sendMessage = 1) do={
    $telegramSend ($message)
    :set sendMessage 0
}