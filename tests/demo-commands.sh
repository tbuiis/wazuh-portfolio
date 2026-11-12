#!/bin/bash
# run from the manager. 192.168.40.121 = debian box with squid + suricata
PROXY=http://192.168.40.121:3128
TARGET=192.168.40.121

case "$1" in
  tunnel)   # 100501
    curl -x $PROXY -sk https://example.com -o /dev/null ;;
  http)     # 100502 - run twice, second one is a cache hit
    curl -x $PROXY -s http://example.com -o /dev/null ;;
  big)      # 100503
    curl -x $PROXY -s http://ipv4.download.thinkbroadband.com/1MB.zip -o /dev/null ;;
  sweep)    # 100513 - suricata wants 5 pings in 10s
    for i in 1 2 3 4 5; do sudo nmap -sn -PE --disable-arp-ping $TARGET >/dev/null; done ;;
  sshscan)  # 100514 - 4 SYNs to 22 in 60s
    for i in 1 2 3 4; do sudo nmap -sS -Pn -p 22 $TARGET >/dev/null; done ;;
  sqli)     # 100515 - has to hit a port that's listening or suricata never sees the request
    curl -s "http://$TARGET:3128/?q=1+UNION+SELECT+1,2,3--" -o /dev/null ;;
  sqlmap)   # 100515
    curl -s -A "sqlmap/1.8" "http://$TARGET:3128/?id=1" -o /dev/null ;;
  *)
    echo "usage: $0 tunnel|http|big|sweep|sshscan|sqli|sqlmap" ;;
esac
