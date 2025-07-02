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
    :put ("icmpHosts = " . [:tostr $icmpHosts])
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
    :put ("httpsHosts = " . [:tostr $httpsHosts])
}

:local totalIcmpDown 0
:local totalHttpsDown 0

:put "Iniciando testes de ICMP"
:put ("icmpHosts = " . [:tostr $icmpHosts])

:foreach i in=$icmpHosts do={
    :put ("Testando " . ($i->"ip"))
    :local result
    :set result [/ping ($i->"ip") src-address=$srcAddr count=2 interval=500ms]
    :put ("result = " . $result)
    :if ($result = 0) do={
        :set totalIcmpDown ($totalIcmpDown + 1)
        :set ($i->"downCicles") ($i->"downCicles" + 1)
        :put ("host: " . $i->"ip" . " downCicles: " . $i->"downCicles")
        :put ("icmpHosts = " . [:tostr $icmpHosts])
        :if (($i->"downCicles") = 1) do={
            :put ("MSG: Falha em " . $i->"ip" . " via ICMP iniciada.")
            $telegramSend ($simbol->"Warn" . "Falha em " . $i->"ip" . " via ICMP iniciada.")
        } else={
            :if (($i->"downCicles") > 1) do={
                :put ("MSG: Falha em " . $i->"ip" . " via ICMP continua. " . $i->"downCicles" . " ciclos.")
                $telegramSend ($simbol->"Warn" . "Falha em " . $i->"ip" . " via ICMP continua. " . $i->"downCicles" . " ciclos.")
            }
        }
    } else={
        :if (($i->"downCicles") > 1) do={
            :put ($i->"ip" . " via ICMP voltou ao normal depois " . $i->"downCicles" . " ciclos.")
            $telegramSend ($simbol->"Ok" . $i->"ip" . " via ICMP voltou ao normal depois " . $i->"downCicles" . " ciclos.")
        }
        :set ($i->"downCicles") 0
    }
}

:put "Iniciando testes de HTTPS"
:foreach h in=$httpsHosts do={
    :local url ("https://" . $h->"host")
    :put ("Testando " . $url)
    :do {
        :local result
        :set result [$urlTest $url]
        :put ($url . " -> " . $result)
        if ($result = 0) do={
            :set totalHttpsDown ($totalHttpsDown + 1)
            :set ($h->"downCicles") ($h->"downCicles" + 1)
            :put ("host: " . $h->"host" . " downCicles: " . $h->"downCicles")
            :if (($h->"downCicles") = 1) do={
                :put ("Falha em " . $h->"host" . " via HTTPS iniciada.")
                $telegramSend ($simbol->"Warn" . "Falha em " . $h->"host" . " via HTTPS iniciada.")
            } else={
                :if (($h->"downCicles") > 1) do={
                    :put ("Falha em " . $h->"host" . " via HTTPS continua. " . $h->"downCicles" . " ciclos.")
                    $telegramSend ($simbol->"Warn" . "Falha em " . $h->"host" . " via HTTPS continua. " . $h->"downCicles" . " ciclos.")
                }
            }
        } else={
            :if ($h->"downCicles" > 1) do={
                :put ($h->"host" . " via HTTPS voltou ao normal depois " . $h->"downCicles" . " ciclos.")
                $telegramSend ($simbol->"Ok" . $h->"host" . " via HTTPS voltou ao normal depois " . $h->"downCicles" . " ciclos.")
            }
            :set ($h->"downCicles") 0
        }
    } on-error={
        :put ("Erro ao testar " $url)
    }
}

:local disponibilidadeIcmp (1 - ($totalIcmpDown / [:len $icmpHosts]))
:local disponibilidadeHttps (1 - ($totalHttpsDown / [:len $httpsHosts]))

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

:put ("icmpHosts = " . [:tostr $icmpHosts])
:put ("httpsHosts = " . [:tostr $httpsHosts])
