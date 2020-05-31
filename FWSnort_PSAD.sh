#Used with ideas @netson from https://gist.github.com/netson/c45b2dc4e835761fbccc
#sed '1 a #This is just a commented line' sedtest.txt
#sed '$ a This is the last line' sedtest.txt

printf '\n%s\n' "Starting Webmin Installation ......";
{
  sudo su

  sed -i.bak '$ a\deb https://download.webmin.com/download/repository sarge contrib' /etc/apt/sources.list
  cd /root
  wget https://download.webmin.com/jcameron-key.asc
  apt-key add jcameron-key.asc

  apt install apt-transport-https -y && apt update -y && apt install webmin -y
  
  exit
} &> /dev/null
printf '\n%s\n' "Starting UFW and GUFW Installation and configuration ......";
{
  sudo su
  apt install ufw gufw -y

  ufw logging on
  ufw allow ssh
  ufw logging on

# custom psad logging directives for iptables

  sed -i.bak '/processed/i\# custom psad logging directives\n
 # Included in case you don't want to use --log-tcp-options
  # -A INPUT -j LOG\n
 # Included in case you don't want to use --log-tcp-options
  # -A FORWARD -j LOG\n
  -A INPUT -j LOG --log-tcp-options --log-prefix "[IPTABLES]"\n
  -A FORWARD -j LOG --log-tcp-options --log-prefix "[IPTABLES]"\n' /etc/ufw/before.rules /etc/ufw/before6.rules /etc/ufw/after.rules /etc/ufw/after6.rules

  echo "[Webmin]
  title=Webmin Portal (HTTPS)
  description=Webmin Portal (HTTPS)
  ports=10000/tcp" >> /etc/ufw/applications.d/ufw-webmin
  
  ufw allow to any app Webmin
  
  echo "# log kernel generated IPTABLES log messages to file
  # each log line will be prefixed by "[IPTABLES]", so search for that
  :msg,contains,"[IPTABLES]" /var/log/iptables.log
  
  # the following stops logging anything that matches the last rule.
  # doing this will stop logging kernel generated IPTABLES log messages to the file
  # normally containing kern.* messages (eg, /var/log/kern.log)
  # older versions of ubuntu may require you to change stop to ~
  & stop" >> /etc/rsyslog.d/10-iptables.conf
  service rsyslog restart
  exit
} &> /dev/null
printf '\n%s\n' "Starting PSAD configuration Installation ......";
{
# Make manual changes to psad.conf
sudo nano /etc/psad/psad.conf


HOME_NET                    192.168.1.0/24;
EXTERNAL_NET                !$HOME_NET;
IPT_SYSLOG_FILE             /var/log/iptables.log;
ENABLE_INTF_LOCAL_NETS         N;
EXPECT_TCP_OPTIONS             Y;

############################################################
# FWSNORT
############################################################

sudo nano /etc/fwsnort/fwsnort.conf

UPDATE_RULES_URL        http://rules.emergingthreats.net/open/snort-edge/emerging-all.rules;
UPDATE_RULES_URL        http://rules.emergingthreats.net/fwrules/emerging-IPTABLES-ALL.rules;
UPDATE_RULES_URL        http://rules.emergingthreats.net/open/snort-2.9.0/emerging-all.rules;

sudo sed -i '18748 s/^/#/' /var/lib/fwsnort/fwsnort.save
sudo /var/lib/fwsnort/fwsnort.sh
fwsnort --update-rules
fwsnort -N --ipt-sync
