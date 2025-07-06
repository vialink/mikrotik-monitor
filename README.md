# Mikrotik Monitor

Este sistema é um monitoramento de rede para roteadores Mikrotik que verifica o estado da rede a partir de testes usando ICMP e HTTPS, enviando notificações via Telegram quando ocorrem alterações no status, ou seja, quando um host muda de estado de online para offline ou vice-versa.

A maior parte dos sistemas de monitoramento utiliza apenas ICMP para identificar o estado de um host, o que pode levar a falsos positivos em situações em que o ICMP é bloqueado por políticas de firewall ou por limitações de prioridade de tratamento desse tipo de pacote nos roteadores. Para evitar isso, este sistema testa tanto ICMP quanto HTTPS para diferentes conjuntos de destinos, o que garante que o estado da rede seja verificado de forma mais precisa.

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

## Instalação e Configuração

1. Copie todos os arquivos `.rsc` para o seu roteador Mikrotik em /files.
2. Importe todos os arquivos `.rsc` para scripts
3. Renomeie o script `rc-local-sample` para `rc-local`
4. Configure o script `rc-local` com suas configurações:
   - Token do bot Telegram (variável `token`)
   - Chat ID do Telegram (variável `chatId`)
   - Endereço de origem para os testes (variável `srcAddr`)
   - Hosts para monitoramento ICMP (variável `icmpHosts`)
   - Endpoints HTTPS para monitoramento (variável `httpsHosts`)
5. Configure o `scheduler.rsc` para definir a frequência das verificações

### Exemplo de Configuração (rc-local)

```routeros
:global token "SEU TOKEN"
:global chatId "SEU CHAT ID"
:global srcAddr "SEU ENDERECO IP"

:global minDisponibilidade "0.5"

:global icmpHosts

:if ([typeof $icmpHosts] = "nothing") do={
    :set icmpHosts [:toarray ""]
    :set icmpHosts  {\
        {"shortName"="registro.br"; "ip"="200.160.2.3"; "downCicles"=0}; \
        {"shortName"="Cloudflare"; "ip"="1.1.1.1"; "downCicles"=0}; \
        {"shortName"="OpenDNS"; "ip"="208.67.222.222"; "downCicles"=0}; \
        {"shortName"="Google"; "ip"="8.8.4.4"; "downCicles"=0}; \
        {"shortName"="Amazon"; "ip"="54.94.33.36"; "downCicles"=0}; \
        {"shortName"="globo.com"; "ip"="186.192.83.12"; "downCicles"=0}; \
        {"shortName"="Uol"; "ip"="108.139.182.15"; "downCicles"=0} \
    }
}

:global httpsHosts

:if ([typeof $httpsHosts] = "nothing") do={
    :set httpsHosts [:toarray ""]
    :set httpsHosts  {\
        {"host"="registro.br"; "downCicles"=0}; \
        {"host"="www.globo.com"; "downCicles"=0}; \
        {"host"="www.uol.com.br"; "downCicles"=0}; \
        {"host"="www.google.com"; "downCicles"=0}; \
        {"host"="www.youtube.com"; "downCicles"=0}; \
        {"host"="www.instagram.com"; "downCicles"=0}; \
        {"host"="www.linkedin.com"; "downCicles"=0}; \
        {"host"="www.whatsapp.com"; "downCicles"=0}; \
        {"host"="www.whitehouse.gov"; "downCicles"=0} \
    }
}
```

**Nota:** *O sistema considera uma queda global quando mais do que 50% ("0.5") dos testes falham, tanto para ICMP quanto para HTTPS. Este fator pode ser alterado na variável `minDisponibilidade` no arquivo `rc-local.rsc`.*

### Exemplo de Configuração do Scheduler

```routeros
# Em scheduler - Executa a cada 5 minutos
/system scheduler
add name=monitor interval=5m on-event="system script run mkt-monitor"

# Ou para execução a cada 1 minuto
/system scheduler
add name=monitor interval=1m on-event="system script run mkt-monitor"
```

## Uso

### Para execução manual, execute o script de monitoramento

```routeros
/system/script/run mkt-monitor
```

### Para execução automática, configure o agendador conforme necessário usando o `scheduler.rsc`

## Estrutura do Projeto

- `conf.rsc`: Configurações do sistema
- `functions.rsc`: Funções utilitárias (testes HTTPS, envio Telegram)
- `mkt-monitor.rsc`: Script principal de monitoramento
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
   - Aumente o número de pings de teste em `mkt-monitor.rsc`

3. **Falsos positivos em testes HTTPS**

   - Verifique se o roteador tem DNS configurado corretamente
   - Confirme se não há bloqueio de HTTPS no firewall
   - Verifique se os certificados SSL dos endpoints são válidos

4. **Scheduler não executa**
   - Verifique se o script está presente no sistema
   - Confirme se o nome do script no scheduler está correto
   - Verifique os logs do sistema por erros

## Instalação Alternativa (via deploy.sh)

Se você preferir, pode usar o script `deploy.sh` para instalar o monitoramento no roteador Mikrotik. Seu uso depende da configuração do arquivo .env, e de acesso ao roteador Mikrotik via SSH com chave pública e de acesso também via ftp.

### Pré-requisitos

- Arquivo .env configurado
- Acesso ao roteador Mikrotik via SSH com chave pública
- Acesso ao roteador Mikrotik via ftp

### Uso

1. Faça uma cópia do arquivo .env.example para .env
2. Configure o arquivo .env com as variáveis necessárias
3. Execute o script `deploy.sh` para instalar o monitoramento no roteador Mikrotik.

### Exemplo de configuração do arquivo `.env`

```bash
HOST="IP ou nome do roteador Mikrotik"
USER="seu_usuario"
PASSWD="sua_senha"
PORT="22"
```

## Contribuição

Contribuições são bem-vindas! Sinta-se à vontade para abrir issues ou enviar pull requests.
