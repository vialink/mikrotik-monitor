:global srcAddr "187.45.173.50"
:global minDisponibilidade "0.5"
:put $minDisponibilidade

:global icmpHosts
:set icmpHosts [:toarray ""]
:foreach h in={"172.56.54.1","1.1.1.1";"208.67.222.222";"8.8.4.4";"54.94.33.36";"8.8.8.8";"186.192.83.12";"10.100.10.62";"10.100.10.61"} do={
    :set icmpHosts ($icmpHosts, $h)
}

:global httpsHosts
:set httpsHosts [:toarray ""]
:foreach h in={"www.globo.com";"www.uol.com.br";"www.google.com"} do={
    :set httpsHosts ($httpsHosts, $h)
}

:global falhaStatus
:if ([:typeof $falhaStatus] != "array") do={ :set falhaStatus [:toarray ""] }

:global falhaCiclos
:if ([:typeof $falhaCiclos] != "array") do={ :set falhaCiclos [:toarray ""] }

:global falhaGlobalDesde
:if ([:typeof $falhaGlobalDesde] != "string") do={ :set falhaGlobalDesde "" }

:global urlTest
:global telegramSend

:local totalIcmp 0
:local totalHttps 0
:local falhasIcmp 0
:local falhasHttps 0

:put "Iniciando testes de ICMP"
:foreach h in=$icmpHosts do={
    :set totalIcmp ($totalIcmp + 1)
    :put ("Testando " . $h)
    :local result [/ping $h src-address=$srcAddr count=2 interval=500ms]
    :if ($result = 0) do={
        :set falhasIcmp ($falhasIcmp + 1)
        :set ($falhaStatus->$h) "ICMP"
        :if ([:typeof ($falhaCiclos->$h)] = "num") do={
            :set ($falhaCiclos->$h) ($falhaCiclos->$h + 1)
        } else={
            :set ($falhaCiclos->$h) 1
        }
        :if (($falhaCiclos->$h) = 1) do={
            :put ("- Falha em " . $h . " via ICMP iniciada.")
            $telegramSend ("--> Falha em " . $h . " via ICMP iniciada.")
        }
    } else={
        :if (([:typeof ($falhaStatus->$h)] = "str") && ($falhaStatus->$h != "")) do={
            :put ("--> " . $h . " via ICMP voltou ao normal depois " . $falhaCiclos->$h . " ciclos.")
            $telegramSend ("--> " . $h . " via ICMP voltou ao normal depois " . $falhaCiclos->$h . " ciclos.")
        }
        :set ($falhaStatus->$h) ""
        :set ($falhaCiclos->$h) 0
    }
}

:put "Iniciando testes de HTTPS"
:foreach h in=$httpsHosts do={
    :set totalHttps ($totalHttps + 1)
    :local url ("https://" . $h)
    :put ("Testando " . $url)
    :do {
        :local result [$urlTest $url]
        :put ($url . " -> " . $result)
        if ($result = 1) do={
            :put "Teste ok"
            :if (([:typeof ($falhaStatus->$h)] = "str") && ($falhaStatus->$h != "")) do={
                :put (">> h" . " via HTTPS voltou ao normal depois de " . $falha->$h . "ciclos.")
                $telegramSend (">> $h" . " via HTTPS voltou ao normal depois de " . $falhaCiclos->$h . " ciclos.")
            }
            :set ($falhaStatus->$h) ""
            :set ($falhaCiclos->$h) 0
        } else={
            :put "Problema"
            :set falhasHttps ($falhasHttps + 1)
            :set ($falhaStatus->$h) "HTTPS"
            :if ([:typeof ($falhaCiclos->$h)] = "num") do={
                :set ($falhaCiclos->$h) ($falhaCiclos->$h + 1)
            } else={
                :set ($falhaCiclos->$h) 1
            }
            :if (($falhaCiclos->$h) = 1) do={
                :put ("--> Falha em " . $h . " via HTTPS iniciada.")
                $telegramSend ("--> Falha em " . $h . " via HTTPS iniciada.")
            }
        }
    } on-error={
        :put ("Erro ao testar " $url)
    }
}

:if ($totalIcmp = 0) do={ :set totalIcmp 1 }
:if ($totalHttps = 0) do={ :set totalHttps 1 }
:local disponibilidadeIcmp (1 - ($falhasIcmp / $totalIcmp))
:local disponibilidadeHttps (1 - ($falhasHttps / $totalHttps))

:if ($disponibilidade < $minDisponibilidade) do={
    :if ($falhaGlobalDesde = "") do={
        :set falhaGlobalDesde [/system clock get time]
        :put ("--> Queda global iniciada as " . $falhaGlobalDesde . ". Disponibilidade: " . ($disponibilidade * 100) . "%")
        $telegramSend ("--> Queda global iniciada as " . $falhaGlobalDesde . ". Disponibilidade: " . ($disponibilidade * 100) . "%")
    }
} else={
    :if ($falhaGlobalDesde != "") do={
        :put (">> Queda global encerrada. Tempo de falha: " . $falhaGlobalDesde . " até " . [/system clock get time])
        $telegramSend (">> Queda global encerrada. Tempo de falha: " . $falhaGlobalDesde . " até " . [/system clock get time])
        :set falhaGlobalDesde ""
    }
}
