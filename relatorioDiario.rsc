:global icmpHosts
:global httpsHosts
:global falhaStatus
:global falhaCiclos
:global telegramSend
:global minDisponibilidade

:local total 0
:local falhas 0
:local relatorio ""

:foreach h in=$icmpHosts do={
  :if ([:typeof $h] = "str") do={
    :set total ($total + 1)
    :if (([:typeof ($falhaStatus->$h)] = "str") && ($falhaStatus->$h != "")) do={
      :set falhas ($falhas + 1)
      :set relatorio ($relatorio . "n❌ " . $h . " (ICMP) em falha há " . $falhaCiclos->$h . " ciclos")
    } else={
      :set relatorio ($relatorio . "n✅ " . $h . " (ICMP) OK")
    }
  }
}

:foreach h in=$httpsHosts do={
  :if ([:typeof $h] = "str") do={
    :set total ($total + 1)
    :if (([:typeof ($falhaStatus->$h)] = "str") && ($falhaStatus->$h != "")) do={
      :set falhas ($falhas + 1)
      :set relatorio ($relatorio . "n❌ " . $h . " (HTTPS) em falha há " . $falhaCiclos->$h . " ciclos")
    } else={
      :set relatorio ($relatorio . "n✅ " . $h . " (HTTPS) OK")
    }
  }
}

:if ($total = 0) do={ :set total 1 }
:local disponibilidade (1 - ($falhas / $total))

:local statusGlobal ""
:if ($disponibilidade < $minDisponibilidade) do={
  :set statusGlobal "⚠️ Queda Global"
} else={
  :set statusGlobal "🟢 Estável"
}

:local msg ("📊 Relatório DiárionDisponibilidade: " . ($disponibilidade * 100) . "%n" . $statusGlobal . "n" . $relatorio)

$telegramSend $msg
