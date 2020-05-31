#Used with ideas @netson from https://gist.github.com/netson/c45b2dc4e835761fbccc

sudo printf "# log kernel generated IPTABLES log messages to file
# each log line will be prefixed by "[IPTABLES]", so search for that
:msg,contains,"[IPTABLES]" /var/log/iptables.log

# the following stops logging anything that matches the last rule.
# doing this will stop logging kernel generated IPTABLES log messages to the file
# normally containing kern.* messages (eg, /var/log/kern.log)
# older versions of ubuntu may require you to change stop to ~
& stop" >  /etc/rsyslog.d/10-iptables.conf

 sudo service rsyslog restart

sudo nano /etc/psad/psad.conf

HOME_NET                    192.168.1.0/24;
EXTERNAL_NET                !$HOME_NET;
IPT_SYSLOG_FILE             /var/log/iptables.log;
Change ENABLE_INTF_LOCAL_NETS to N

printf '$-73i\n# custom psad logging directives\n
-A INPUT -j LOG\n
-A FORWARD -j LOG\n
-A INPUT -j LOG --log-tcp-options --log-prefix "[IPTABLES]"\n
-A FORWARD -j LOG --log-tcp-options --log-prefix "[IPTABLES]"\n.\nw\n' | ed -s /etc/ufw/before.rules /etc/ufw/before6.rules /etc/ufw/after.rules /etc/ufw/after6.rules







sudo ufw logging on
sudo ufw allow ssh

# custom psad logging directives
-A INPUT -j LOG
-A FORWARD -j LOG
-A INPUT -j LOG --log-tcp-options --log-prefix "[IPTABLES]"
-A FORWARD -j LOG --log-tcp-options --log-prefix "[IPTABLES]"



############################################################
FWSNORT
############################################################

sudo nano /etc/fwsnort/fwsnort.conf

UPDATE_RULES_URL        http://rules.emergingthreats.net/open/snort-edge/emerging-all.rules;
UPDATE_RULES_URL        http://rules.emergingthreats.net/fwrules/emerging-IPTABLES-ALL.rules;
UPDATE_RULES_URL        http://rules.emergingthreats.net/open/snort-2.9.0/emerging-all.rules;

sudo sed -i '18748 s/^/#/' /var/lib/fwsnort/fwsnort.save
sudo /var/lib/fwsnort/fwsnort.sh

sudo su

apt install ufw gufw -y

ufw logging on

nano /etc/ufw/before.rules

# custom psad logging directives
-A INPUT -j LOG
-A FORWARD -j LOG
-A INPUT -j LOG --log-tcp-options --log-prefix "[IPTABLES]"
-A FORWARD -j LOG --log-tcp-options --log-prefix "[IPTABLES]"

nano /etc/ufw/before6.rules

# custom psad logging directives
-A INPUT -j LOG
-A FORWARD -j LOG
-A INPUT -j LOG --log-tcp-options --log-prefix "[IPTABLES]"
-A FORWARD -j LOG --log-tcp-options --log-prefix "[IPTABLES]"



printf "[Webmin]
title=Webmin Portal (HTTPS)
description=Webmin Portal (HTTPS)
ports=10000/tcp" > /etc/ufw/applications.d/ufw-webmin


ufw allow to any app Webmin

fwsnort --update-rules
fwsnort -N --ipt-sync

nano /etc/ufw/applications.d/ufw-webmin

