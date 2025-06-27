:global srcAddr "187.45.173.50"
:global minDisponibilidade "0.5"
:global simbolOk "\E2\9C\85"
:global simbolFail "\E2\9D\8C"
:global simbolWarn "\E2\9A\A0\EF\B8\8F"
:global simbolDown "\F0\9F\94\B4"
:global simbolUp "\F0\9F\9F\A2"
:global simbolUnstable "\F0\9F\9F\A1"
:global simbolActive "\F0\9F\94\B5"
:global simbolUnknown "\E2\9A\AA"
:global simbolWaiting "\E2\8F\B3"
:global simbolRetry "\F0\9F\94\81"
:global simbolMonitoring "\F0\9F\94\82"
:global simbolIncident "\F0\9F\9A\A8"
:global simbolBoom "\F0\9F\92\A5"
:global simbolBomb "\F0\9F\92\A3"
:global simbolFire "\F0\9F\94\A5"
:global simbolBlocked "\F0\9F\9B\91"
:global simbolRadio "\F0\9F\93\A1"
:global simbolSignal "\F0\9F\93\B6"
:global simbolInet "\F0\9F\8C\90"
:global simbolPower "\F0\9F\94\8C"
:global simbolBattery "\F0\9F\94\8E"
:global simbolBatteryCharging "\F0\9F\94\8D"
:global simbolBatteryLow "\F0\9F\94\8B"
:global simbolBatteryMedium "\F0\9F\94\8C"
:global simbolBatteryHigh "\F0\9F\94\8D"
:global simbolBatteryFull "\F0\9F\94\8E"

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
            $telegramSend ($simbolWarn . "--> Falha em " . $h . " via ICMP iniciada.")
        }
    } else={
        :if (([:typeof ($falhaStatus->$h)] = "str") && ($falhaStatus->$h != "")) do={
            :put ("--> " . $h . " via ICMP voltou ao normal depois " . $falhaCiclos->$h . " ciclos.")
            $telegramSend ($simbolWarn . "--> " . $h . " via ICMP voltou ao normal depois " . $falhaCiclos->$h . " ciclos.")
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
                $telegramSend ($simbolWarn . ">> $h" . " via HTTPS voltou ao normal depois de " . $falhaCiclos->$h . " ciclos.")
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
                :put ($simbolWarn . "--> Falha em " . $h . " via HTTPS iniciada.")
                $telegramSend ($simbolWarn . "--> Falha em " . $h . " via HTTPS iniciada.")
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
        $telegramSend ($simbolWarn . "--> Queda global iniciada as " . $falhaGlobalDesde . ". Disponibilidade: " . ($disponibilidade * 100) . "%")
    }
} else={
    :if ($falhaGlobalDesde != "") do={
        :put (">> Queda global encerrada. Tempo de falha: " . $falhaGlobalDesde . " até " . [/system clock get time])
        $telegramSend ("$simbolWarn . >> Queda global encerrada. Tempo de falha: " . $falhaGlobalDesde . " até " . [/system clock get time])
        :set falhaGlobalDesde ""
    }
}
