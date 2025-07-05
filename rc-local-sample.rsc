:global token 
:global chatId 
:global srcAddr 

:set token ""
:set chatId ""
:set srcAddr ""

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
        {"shortName"="MaisLink"; "ip"="10.100.10.62"; "downCicles"=0}; \
        {"shortName"="MaisLink"; "ip"="10.100.10.61"; "downCicles"=0} \
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
        {"host"="www.facebook.com"; "downCicles"=0}; \
        {"host"="www.instagram.com"; "downCicles"=0}; \
        {"host"="www.linkedin.com"; "downCicles"=0}; \
        {"host"="www.whatsapp.com"; "downCicles"=0}; \
        {"host"="www.whitehouse.gov"; "downCicles"=0} \
    }
}
