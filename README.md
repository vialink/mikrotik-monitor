# Mikrotik Monitor

This system is a network monitoring solution for Mikrotik routers that checks the network status through ICMP and HTTPS tests, sending notifications via Telegram when status changes occur, i.e., when a host changes state from online to offline or vice versa.

Most monitoring systems only use ICMP to identify a host's state, which can lead to false positives in situations where ICMP is blocked by firewall policies or due to packet priority handling limitations in routers. To avoid this, this system tests both ICMP and HTTPS for different sets of destinations, ensuring that the network state is verified more accurately.

## Features

- Host monitoring via ICMP (ping)
- HTTPS endpoint verification
- Telegram notifications
- Flexible host and endpoint configuration
- Downtime cycle counting
- Router identification by name

## Prerequisites

- Mikrotik router with RouterOS v6.45.9 or higher
- Configured Telegram bot (token and chat_id)
- Internet access on the router
- Write permissions on the RouterOS file system

## Installation and Configuration

1. Copy all `.rsc` files to your Mikrotik router in /files.
2. Import all `.rsc` files as scripts
3. Rename the `rc-local-sample` script to `rc-local`
4. Configure the `rc-local` script with your settings:
   - Telegram bot token (variable `token`)
   - Telegram Chat ID (variable `chatId`)
   - Source address for tests (variable `srcAddr`)
   - Hosts for ICMP monitoring (variable `icmpHosts`)
   - HTTPS endpoints for monitoring (variable `httpsHosts`)
5. Configure `scheduler.rsc` to set the check frequency

### Configuration Example (rc-local)

```routeros
:global token "YOUR TOKEN"
:global chatId "YOUR CHAT ID"
:global srcAddr "YOUR IP ADDRESS"

:global minAvailability "0.5"

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

**Note:** *The system considers a global outage when more than 50% ("0.5") of the tests fail, for both ICMP and HTTPS. This factor can be modified in the `minAvailability` variable in the `rc-local.rsc` file.*

### Scheduler Configuration Example

```routeros
# In scheduler - Runs every 5 minutes
/system scheduler
add name=monitor interval=5m on-event="system script run mkt-monitor"

# Or for execution every 1 minute
/system scheduler
add name=monitor interval=1m on-event="system script run mkt-monitor"
```

## Usage

### For manual execution, run the monitoring script

```routeros
/system/script/run mkt-monitor
```

### For automatic execution, configure the scheduler as needed using `scheduler.rsc`

## Project Structure

- `conf.rsc`: System configurations
- `functions.rsc`: Utility functions (HTTPS tests, Telegram sending)
- `mkt-monitor.rsc`: Main monitoring script
- `scheduler.rsc`: Scheduler configuration
- `rc-local-sample.rsc`: Example configuration for initialization

## Notification Format

Notifications sent via Telegram follow this format:

```text
------------------------------
ROUTER_NAME - SOURCE_IP
DATE_AND_TIME
------------------------------
ICMP Tests
    🔴 8.8.8.8 (DNS Google) - 3 cycle(s)
    🟢 1.1.1.1 (DNS Cloudflare) - Online

HTTPS Tests
    ❌ https://api.example.com (API) - 1 cycle(s)
------------------------------
```

Symbol legend:

- 🟢 Host online (ICMP)
- 🔴 Host offline (ICMP)
- ✅ General HTTPS access state ok
- ❌ General HTTPS access state inaccessible
- ⚠️ State change warning

## Troubleshooting

### Common Issues

1. **Notifications are not being sent**

   - Verify if the Telegram token is correct
   - Confirm if the chat_id is correct
   - Check if the router has Internet access
   - Test connectivity with api.telegram.org

2. **False positives in ICMP tests**

   - Check if the source address (srcAddr) is correct
   - Confirm if there are no firewall rules blocking ICMP
   - Increase the number of test pings in `mkt-monitor.rsc`

3. **False positives in HTTPS tests**

   - Check if the router has DNS properly configured
   - Confirm if there's no HTTPS blocking in the firewall
   - Verify if the SSL certificates of the endpoints are valid

4. **Scheduler not executing**
   - Check if the script is present in the system
   - Confirm if the script name in the scheduler is correct
   - Check system logs for errors

## Alternative Installation (via deploy.sh)

If you prefer, you can use the `deploy.sh` script to install the monitoring on your Mikrotik router. Its use depends on the .env file configuration, and access to the Mikrotik router via SSH with public key and also via ftp.

### Prerequisites

- Configured .env file
- Access to Mikrotik router via SSH with public key
- Access to Mikrotik router via ftp

### Usage

1. Make a copy of the .env.example file to .env
2. Configure the .env file with the necessary variables
3. Run the `deploy.sh` script to install the monitoring on the Mikrotik router.

### Example .env file configuration

```bash
HOST="IP or Mikrotik router name"
USER="your_username"
PASSWD="your_password"
PORT="22"
```

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.
