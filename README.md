# wazuh-portfolio
Wazuh home lab with custom decoders and rules for squid proxy logs, and Suricata IDS alerts, plus a dashboard

# wazuh-squid-suricata

Home lab where I set up Wazuh to pick up Squid proxy logs and Suricata IDS alerts, wrote custom decoders/rules for them, and built a dashboard for it.

## Lab

```
debian vm (192.168.40.121)
  squid    -> /var/log/squid/access.log  --+
  suricata -> /var/log/suricata/eve.json --+-- wazuh agent --> wazuh manager (192.168.40.244)
                                                                 analysisd -> alerts.json -> filebeat -> indexer -> dashboard
windows server 2022 (192.168.40.144) -- wazuh agent ------------^
```

Everything is the all-in-one Wazuh 4.14 install on one Debian box. The Windows agent is mostly there for the default event log rules (logon failures etc), nothing custom on it yet.

## What's in here

```
decoders/0010-squid_decoders.xml        squid access.log decoder
rules/0500-squid_rules.xml              squid rules 100501-100503
rules/0501-suricata_custom_rules.xml    suricata rules 100510-100515
suricata/local.rules                    my suricata signatures (sid 9000001-9000005)
agent/localfile.xml                     what the agent needs to ship the logs
dashboard/                              dashboard export (import under Dashboards Management > Saved objects)
tests/                                  sample logs for wazuh-logtest + script to trigger each rule
```

Decoders and rules go in `/var/ossec/etc/decoders` and `/var/ossec/etc/rules` on the manager. `local.rules` goes in `/var/lib/suricata/rules/` and has to be listed under `rule-files` in suricata.yaml.

## Rules

| ID | Level | Fires on |
|----|-------|----------|
| 100501 | 7 | squid TCP_TUNNEL (HTTPS CONNECT through the proxy) |
| 100502 | 3 | squid TCP_MISS / TCP_HIT / TCP_MEM_HIT, normal web requests |
| 100503 | 6 | squid response of 600000+ bytes |
| 100510 | 12 | suricata severity 1 alert |
| 100511 | 10 | suricata severity 2 alert |
| 100512 | 10 | suricata category Web Application Attack |
| 100513 | 8 | suricata category Network Scan / Attempted Information Leak |
| 100514 | 10 | suricata category Attempted Administrator Privilege Gain |
| 100515 | 10 | SQL injection / sqlmap / UNION SELECT in the alert |

Squid rules hang off the built-in 35000. Suricata ones hang off 86601 (the built-in "event_type is alert" rule), eve.json is JSON so Wazuh decodes it without a custom decoder.

Suricata signatures:

- 9000001 SSH scan, 4 SYNs to port 22 from the same source in 60s
- 9000003 UNION + SELECT in the URI
- 9000004 sqlmap user agent
- 9000005 ping sweep, 5 echo requests in 10s

## Testing

Each rule was checked with `wazuh-logtest` first:

```
sudo /var/ossec/bin/wazuh-logtest < tests/squid-samples.log
sudo /var/ossec/bin/wazuh-logtest < tests/suricata-samples.json
sudo /var/ossec/bin/wazuh-analysisd -t
```

Then with real traffic using `tests/demo-commands.sh` (run on the manager, e.g. `./demo-commands.sh sqli`).

