# Mikrotik Monitor

Este sistema é um monitoramento de rede para roteadores Mikrotik que verifica a disponibilidade de hosts via ICMP (ping) e HTTPS, enviando notificações via Telegram quando ocorrem alterações no status.

## Características

- Monitoramento de hosts via ICMP (ping)
- Verificação de endpoints HTTPS
- Notificações via Telegram
- Configuração flexível de hosts e endpoints
- Contagem de ciclos de indisponibilidade
- Identificação do roteador por nome

## Pré-requisitos

- Roteador Mikrotik com RouterOS v6.45.9 ou superior
- Bot do Telegram configurado (token e chat_id)
- Acesso à internet no roteador
- Permissões de escrita no sistema de arquivos do RouterOS

## Configuração

1. Copie todos os arquivos `.rsc` para o seu roteador Mikrotik
2. Importe todos os arquivos `.rsc` para scripts
3. Configure o arquivo `conf.rsc` com suas configurações:
   - Token do bot Telegram
   - Chat ID do Telegram
   - Hosts para monitoramento ICMP
   - Endpoints HTTPS para monitoramento
   - Endereço de origem para os testes

### Exemplo de Configuração

```routeros
# Em conf.rsc
:global token "seu_token_do_telegram"
:global chatId "seu_chat_id"
:global srcAddr "192.168.1.1"  # Endereço IP de origem para os testes

# Configuração dos hosts ICMP para monitoramento
:global icmpHosts [:toarray {}]
:set ($icmpHosts->0) {"ip"="8.8.8.8"; "shortName"="DNS Google"; "downCicles"=0}
:set ($icmpHosts->1) {"ip"="1.1.1.1"; "shortName"="DNS Cloudflare"; "downCicles"=0}

# Configuração dos hosts HTTPS para monitoramento
:global httpsHosts [:toarray {}]
:set ($httpsHosts->0) {"url"="https://api.example.com"; "shortName"="API"; "downCicles"=0}
```

1. Configure o `scheduler.rsc` para definir a frequência das verificações

### Exemplo de Configuração do Scheduler

```routeros
# Em scheduler.rsc - Executa a cada 5 minutos
/system scheduler
add name=monitor interval=5m on-event="system script run monitoramento-composto"

# Ou para execução a cada 1 minuto
/system scheduler
add name=monitor interval=1m on-event="system script run monitoramento-composto"
```

## Uso

1. Execute o script de configuração inicial:

```routeros
/system/script/run conf
```

1. Execute o script de monitoramento:

```routeros
/system/script/run monitoramento-composto
```

1. Para execução automática, configure o agendador conforme necessário usando o `scheduler.rsc`

## Estrutura do Projeto

- `conf.rsc`: Configurações principais do sistema
- `functions.rsc`: Funções utilitárias (testes HTTPS, envio Telegram)
- `monitoramento-composto.rsc`: Script principal de monitoramento
- `scheduler.rsc`: Configuração do agendador
- `rc-local-sample.rsc`: Exemplo de configuração para inicialização

## Formato das Notificações

As notificações enviadas pelo Telegram seguem o seguinte formato:

```text
------------------------------
NOME_DO_ROTEADOR - IP_ORIGEM
DATA_E_HORA
------------------------------
Testes de ICMP
    🔴 8.8.8.8 (DNS Google) - 3 ciclo(s)
    🟢 1.1.1.1 (DNS Cloudflare) - Online

Testes de HTTPS
    ❌ https://api.example.com (API) - 1 ciclo(s)
------------------------------
```

Legenda dos símbolos:

- 🟢 Host online (ICMP)
- 🔴 Host offline (ICMP)
- ✅ Estado geral de acssso via HTTPS ok
- ❌ Estado geral de acssso via HTTPS inacessível
- ⚠️ Aviso de alteração de estado

## Troubleshooting

### Problemas Comuns

1. **Notificações não são enviadas**
   - Verifique se o token do Telegram está correto
   - Confirme se o chat_id está correto
   - Verifique se o roteador tem acesso à Internet
   - Teste a conectividade com api.telegram.org

2. **Falsos positivos em testes ICMP**
   - Verifique se o endereço de origem (srcAddr) está correto
   - Confirme se não há regras de firewall bloqueando ICMP
   - Aumente o número de pings de teste em `monitoramento-composto.rsc`

3. **Falsos positivos em testes HTTPS**
   - Verifique se o roteador tem DNS configurado corretamente
   - Confirme se não há bloqueio de HTTPS no firewall
   - Verifique se os certificados SSL dos endpoints são válidos

4. **Scheduler não executa**
   - Verifique se o script está presente no sistema
   - Confirme se o nome do script no scheduler está correto
   - Verifique os logs do sistema por erros

## Contribuição

Contribuições são bem-vindas! Sinta-se à vontade para abrir issues ou enviar pull requests.
