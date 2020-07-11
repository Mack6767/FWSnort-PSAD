#Used with ideas @netson from https://gist.github.com/netson/c45b2dc4e835761fbccc
#!/bin/bash
touch /home/${USER}/Documents/webmin_install.log
touch /home/${USER}/Documents/rsyslog_diag.log
touch /home/${USER}/Documents/ufw_install.log
touch /home/${USER}/Documents/fwsnort_install.log
touch /home/${USER}/Documents/psad_install.log
echo "Would you like to install Webmin? Please type Yes or No, followed by [ENTER]"
read install
if [[ $install == "Yes" ]]; then
printf '\n%s\n' "Starting Webmin Installation ......";
{
  sudo su
  sed -i.bak '$ a\deb https://download.webmin.com/download/repository sarge contrib' /etc/apt/sources.list
  cd /root
  wget https://download.webmin.com/jcameron-key.asc
  apt-key add jcameron-key.asc
  apt install apt-transport-https -y && apt update -y && apt install webmin -y
  exit
} &> /home/${USER}/Documents/webmin_install.log
elif [[ $install == "No" ]]; then
printf '\n%s\n' "Starting UFW and GUFW Installation and configuring for FWSnort with PSAD ......";
echo "First things first, lets get your network information. Please enter your nework in CIDR notation (192.168.1.0/24), followed by [ENTER]:"
read network
{
  sudo su
  apt install ufw gufw -y
  ufw allow from $network app SSH
  ufw logging on
  sed -i.bak '/processed/i\# custom psad logging directives\n-A INPUT -j LOG --log-tcp-options --log-prefix "[IPTABLES]"\n-A FORWARD -j LOG --log-tcp-options --log-prefix "[IPTABLES]"\n' /etc/ufw/before.rules /etc/ufw/before6.rules /etc/ufw/after.rules /etc/ufw/after6.rules
  if [[ $install == "Yes" ]]; then
    ufw allow from $network app Webmin
    echo "[Webmin]
    title=Webmin Portal (HTTPS)
    description=Webmin Portal (HTTPS)
    ports=10000/tcp" >> /etc/ufw/applications.d/ufw-webmin
  elif [[ $install == "No" ]]; then
    echo "Webmin not installed via this script, not including rule."
  fi
  echo "# log kernel generated IPTABLES log messages to file
  # each log line will be prefixed by "[IPTABLES]", so search for that
  :msg,contains,"[IPTABLES]" /var/log/iptables.log
  # the following stops logging anything that matches the last rule.
  # doing this will stop logging kernel generated IPTABLES log messages to the file
  # normally containing kern.* messages (eg, /var/log/kern.log)
  # older versions of ubuntu may require you to change stop to ~
  & stop" >> /etc/rsyslog.d/10-iptables.conf
  exit
} &> /home/${USER}/Documents/ufw_install.log
printf '\n%s\n' "Checking if rsyslog is running ....";
{
  sudo ps -C httpd >/dev/null && echo "Running" || echo "Not running"
  read check_one
  if [[ $check_one == "Running" ]]; then
      echo "Service is running"
  elif [[ $check_one == "Not running" ]]; then
    echo "Service is not running" && printf '\n%s\n' "Attempting to start rsyslog service ....";
    sudo service rsyslog start >/dev/null && ps -C httpd >/dev/null && echo "Running" || echo "Not running"
    read result
      if [[ $result == "Running" ]]; then
        echo "rsyslog service has been started"
      elif [[ $result == "Not running" ]]; then
        sudo systemctl list-unit-files | grep rsyslog
        echo "Does it show as 'masked'? Type Yes or No, followed by [ENTER]:"
        read masked
          if [[ $masked == "Yes" ]]; then
            sudo systemctl unmask rsyslog
            sudo service rsyslog start
          elif [[ $masked == "No" ]]; then
            sudo service rsyslog start && sudo ps -C httpd >/dev/null && echo "Running" || echo "Not running"
            read check_two
              if [[ $check_two == "Not running" ]]; then
                printf '\n%s\n' "Further diagnostics are required, start with journalctl -xe | grep rsyslog ...." && end
              fi
          fi
      fi
  fi
} &> /home/${USER}/Documents/rsyslog_diag.log
fi
printf '\n%s\n' "Starting FWSnort configuration ......";
{
  sudo su
  apt install fwsnort -y
  echo "Make manual changes to fwsnort.conf located at /etc/fwsnort/fwsnort.conf:
  HOME_NET                YOUR_NETWORK_CIDR; #EX: 192.168.0.0/24
  EXTERNAL_NET            !$HOME_NET; #Denotes anything not within your network CIDR
  Add the following two lines to UPDATE_RULES_URL:
  UPDATE_RULES_URL        http://rules.emergingthreats.net/open/snort-edge/emerging-all.rules;
  UPDATE_RULES_URL        http://rules.emergingthreats.net/fwrules/emerging-IPTABLES-ALL.rules;"
  fwsnort --update-rules
  fwsnort -N --ipt-sync
  /sbin/iptables-restore < /var/lib/fwsnort/fwsnort.save
  exit
} &> /home/${USER}/Documents/fwsnort_install.log
printf '\n%s\n' "Starting PSAD configuration ......";
{
  sudo su
  apt install psad -y
  echo "Make manual changes to psad.conf located at /etc/psad/psad.conf
  HOME_NET                    YOUR_NETWORK_CIDR; #EX: 192.168.0.0/24
  EXTERNAL_NET                !$HOME_NET; #Denotes anything not within your network CIDR
  IPT_SYSLOG_FILE             /var/log/iptables.log; #Points to the new log created earlier
  ENABLE_INTF_LOCAL_NETS         N; #Prevents PSAD from assuming the network automatically
  EXPECT_TCP_OPTIONS             Y;"
  psad -K
  psad --fw-include-ips
  exit
} &> /home/${USER}/Documents/psad_install.log

#service rsyslog restart
#exit

# If you go the fwsnort.sh route, you're going to need this:
#sudo sed -i '18748 s/^/#/' /var/lib/fwsnort/fwsnort.save 
# Change the number to whatever line is having issues because IPTables is cray cray, rinse and repeat.

##      sudo service rsyslog restart >/dev/null && echo "rsyslog service has been restarted"
#sed '1 a #This is just a commented line' sedtest.txt
#sed '$ a This is the last line' sedtest.txt
# ps -C httpd >/dev/null && echo "Running" || echo "Not running"
