:global srcAddr "187.45.173.50"
:global minDisponibilidade "0.5"
:global simbol
:global urlTest
:global telegramSend
:global countIcmpGlobalDown 
:global countHttpsGlobalDown 
:global icmpHosts
:global httpsHosts

if ([typeof $countIcmpGlobalDown] = "nothing") do={
    :set countIcmpGlobalDown 0
}

if ([typeof $countHttpsGlobalDown] = "nothing") do={
    :set countHttpsGlobalDown 0
}

:if ([typeof $icmpHosts] != "array" or [typeof $icmpHosts] = "nothing") do={
    :put "Iniciando a variavel icmpHosts"
    :set icmpHosts [:toarray ""]
    :set icmpHosts  {\
        {"ip"="172.56.54.1"; "downCicles"=0};\
        {"ip"="1.1.1.1"; "downCicles"=0};\
        {"ip"="208.67.222.222"; "downCicles"=0};\
        {"ip"="8.8.4.4"; "downCicles"=0};\
        {"ip"="54.94.33.36"; "downCicles"=0};\
        {"ip"="8.8.8.8"; "downCicles"=0};\
        {"ip"="186.192.83.12"; "downCicles"=0};\
        {"ip"="10.100.10.62"; "downCicles"=0};\
        {"ip"="10.100.10.61"; "downCicles"=0}
    }
}

:if ([typeof $httpsHosts] != "array" or [typeof $httpsHosts] = "nothing") do={
    :put "Iniciando a variavel httpsHosts"
    :set httpsHosts [:toarray ""]
    :set httpsHosts  {\
        {"host"="www.globo.com"; "downCicles"=0};\
        {"host"="www.uol.com.br"; "downCicles"=0};\
        {"host"="www.google.com"; "downCicles"=0};\
        {"host"="www.youtube.com"; "downCicles"=0};\
        {"host"="www.facebook.com"; "downCicles"=0};\
        {"host"="www.twitter.com"; "downCicles"=0};\
        {"host"="www.instagram.com"; "downCicles"=0};\
        {"host"="www.linkedin.com"; "downCicles"=0};\
        {"host"="www.tiktok.com"; "downCicles"=0};\
        {"host"="www.whatsapp.com"; "downCicles"=0}
    }
}

:local totalIcmpDown 0
:put "Iniciando testes de ICMP"

:for i from=0 to=([:len $icmpHosts] - 1) do={
    :local item ($icmpHosts->$i)
    :local ip ($item->"ip")
    :local dc ($item->"downCicles")

    :put ("Testando " . $ip)
    :local result
    :set result [/ping $ip src-address=$srcAddr count=2 interval=500ms]

    :put ("result = " . $result)
    :if ($result = 0) do={
        :set totalIcmpDown ($totalIcmpDown + 1)
        :set dc ($dc + 1)
        :put ("ip: " . $ip . " downCicles: " . $dc)
        :put ("icmpHosts = " . [:tostr $icmpHosts])
        :if ($dc = 1) do={
            :put ("MSG: Falha em " . $ip . " via ICMP iniciada.")
            $telegramSend ($simbol->"Warn" . "Falha em " . $ip . " via ICMP iniciada.")
        } else={
            :if ($dc > 1) do={
                :put ("MSG: Falha em " . $ip . " via ICMP continua. " . $dc . " ciclos.")
                $telegramSend ($simbol->"Warn" . "Falha em " . $ip . " via ICMP continua. " . $dc . " ciclos.")
            }
        }
    } else={
        :if ($dc > 0) do={
            :put ($ip . " via ICMP voltou ao normal depois de " . $dc . " ciclos.")
            $telegramSend ($simbol->"Ok" . $ip . " via ICMP voltou ao normal depois de " . $dc . " ciclos.")
        }
        :set dc 0
    }

    # Atualiza o item no array
    :set ($icmpHosts->$i) {"ip"=$ip; "downCicles"=$dc}
    :put ""
}

:local totalHttpsDown 0
:put "Iniciando testes de HTTPS"

:for i from=0 to=([:len $httpsHosts] - 1) do={
    :local item ($httpsHosts->$i)
    :local host ($item->"host")
    :local dc ($item->"downCicles")

    :put ("Testando " . $host)
    :local url ("https://" . $host)

    :do {
        :local result
        :set result [$urlTest $url]
        :put ($url . " -> " . $result)
        if ($result = 0) do={
            :set totalHttpsDown ($totalHttpsDown + 1)
            :set dc ($dc + 1)
            :put ("host: " . $host . " downCicles: " . $dc)
            :if ($dc = 1) do={
                :put ("Falha em " . $host . " via HTTPS iniciada.")
                $telegramSend ($simbol->"Warn" . "Falha em " . $host . " via HTTPS iniciada.")
            } else={
                :if ($dc > 1) do={
                    :put ("Falha em " . $host . " via HTTPS continua. " . $dc . " ciclos.")
                    $telegramSend ($simbol->"Warn" . "Falha em " . $host . " via HTTPS continua. " . $dc . " ciclos.")
                }
            }
        } else={
            :if ($dc > 0) do={
                :put ($host . " via HTTPS voltou ao normal depois " . $dc . " ciclos.")
                $telegramSend ($simbol->"Ok" . $host . " via HTTPS voltou ao normal depois " . $dc . " ciclos.")
            }
            :set dc 0
        }
    } on-error={
        :put ("Erro ao testar " $url)
    }
    # Atualiza o item no array
    :set ($httpsHosts->$i) {"host"=$host; "downCicles"=$dc}
    :put ""
}

:local disponibilidadeIcmp (1 - ($totalIcmpDown / [:len $icmpHosts]))

:if ($disponibilidadeIcmp < $minDisponibilidade) do={
    :set countIcmpGlobalDown ($countIcmpGlobalDown + 1)
    :if ($countIcmpGlobalDown = 1) do={
        :put ("Queda Global ICMP iniciada. Disponibilidade: " . ($disponibilidadeIcmp * 100) . "%")
        $telegramSend ($simbol->"Fail" . "Queda Global ICMP iniciada. Disponibilidade: " . ($disponibilidadeIcmp * 100) . "%")
    } else={
        :if ($countIcmpGlobalDown > 1) do={
            :put ("Queda Global ICMP continua. Disponibilidade: " . ($disponibilidadeIcmp * 100) . "%" . " Ciclos: " . $countIcmpGlobalDown)
            $telegramSend ($simbol->"Fail" . "Queda Global ICMP continua. Disponibilidade: " . ($disponibilidadeIcmp * 100) . "%" . " Ciclos: " . $countIcmpGlobalDown)
        }
    }
} else={
    :put ("Queda Global ICMP encerrada. Ciclos: " . $countIcmpGlobalDown)
    $telegramSend ($simbol->"Ok" . "Queda Global ICMP encerrada. Ciclos: " . $countIcmpGlobalDown)
    :set countIcmpGlobalDown 0
}

:local disponibilidadeHttps (1 - ($totalHttpsDown / [:len $httpsHosts]))

:if ($disponibilidadeHttps < $minDisponibilidade) do={
    :set countHttpsGlobalDown ($countHttpsGlobalDown + 1)
    :if ($countHttpsGlobalDown = 1) do={
        :put ("Queda Global HTTPS iniciada. Disponibilidade: " . ($disponibilidadeHttps * 100) . "%")
        $telegramSend ($simbol->"Fail" . "Queda Global HTTPS iniciada. Disponibilidade: " . ($disponibilidadeHttps * 100) . "%")
    } else={
        :if ($countHttpsGlobalDown > 1) do={
            :put ("Queda Global HTTPS continua. Disponibilidade: " . ($disponibilidadeHttps * 100) . "%" . " Ciclos: " . $countHttpsGlobalDown)
            $telegramSend ($simbol->"Fail" . "Queda Global HTTPS continua. Disponibilidade: " . ($disponibilidadeHttps * 100) . "%" . " Ciclos: " . $countHttpsGlobalDown)
        }
    }
} else={
    :if ($countHttpsGlobalDown > 1) do={
        :put ("Queda Global HTTPS encerrada. Ciclos: " . $countHttpsGlobalDown)
        $telegramSend ($simbol->"Ok" . "Queda Global HTTPS encerrada. Ciclos: " . $countHttpsGlobalDown)
        :set countHttpsGlobalDown 0
    }
}
