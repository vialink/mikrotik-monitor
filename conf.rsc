:global icmpHosts
:global httpsHosts
:global sendMessage

:if ([typeof $sendMessage] = "nothing") do={
    :set sendMessage 1
}

:global simbol {""}
:set ($simbol->"Ok") "\E2\9C\85" 
:set ($simbol->"Fail") "\E2\9D\8C"
:set ($simbol->"Warn") "\E2\9A\A0\EF\B8\8F"
:set ($simbol->"Online") "\F0\9F\9F\A2"
:set ($simbol->"Offline") "\F0\9F\94\B4"
:set ($simbol->"PointRight") "\F0\9F\91\89"
:set ($simbol->"PointLeft") "\F0\9F\91\88"
:set ($simbol->"PointUp") "\F0\9F\91\86"
:set ($simbol->"PointDown") "\F0\9F\91\87"

:global LF "%0A"

/system/script/run functions
/system/script/run rc-local