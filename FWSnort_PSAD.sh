#Used with ideas @netson from https://gist.github.com/netson/c45b2dc4e835761fbccc
#sed '1 a #This is just a commented line' sedtest.txt
#sed '$ a This is the last line' sedtest.txt
#!/bin/bash
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
  echo "First things first, lets get your network information. Please enter your nework in CIDR notation (192.168.1.0/24), followed by [ENTER]:"
  read network
  sudo apt install ufw gufw -y
  sudo ufw allow from $network app SSH
  sudo ufw logging on
  sudo sed -i.bak '/processed/i\# custom psad logging directives\n# Included in case you do not want to use --log-tcp-options\n# sudo iptables -A INPUT -j LOG\n# Included in case you do not want to use --log-tcp-options\n# sudo iptables -A FORWARD -j LOG\n-A INPUT -j LOG --log-tcp-options --log-prefix "[IPTABLES]"\n-A FORWARD -j LOG --log-tcp-options --log-prefix "[IPTABLES]"\n' /etc/ufw/before.rules /etc/ufw/before6.rules /etc/ufw/after.rules /etc/ufw/after6.rules

  echo "[Webmin]
  title=Webmin Portal (HTTPS)
  description=Webmin Portal (HTTPS)
  ports=10000/tcp" >> /etc/ufw/applications.d/ufw-webmin

  sudo ufw allow from $network app Webmin

  echo "# log kernel generated IPTABLES log messages to file
  # each log line will be prefixed by "[IPTABLES]", so search for that
  :msg,contains,"[IPTABLES]" /var/log/iptables.log

  # the following stops logging anything that matches the last rule.
  # doing this will stop logging kernel generated IPTABLES log messages to the file
  # normally containing kern.* messages (eg, /var/log/kern.log)
  # older versions of ubuntu may require you to change stop to ~
  & stop" >> /etc/rsyslog.d/10-iptables.conf

  printf '\n%s\n' "Checking if rsyslog is running ....";
  {
 # ps -C httpd >/dev/null && echo "Running" || echo "Not running"
  if ps -C httpd >/dev/null
    then
      echo "Service is running"
      sudo service rsyslog restart >/dev/null && echo "rsyslog service has been restarted"
    else
      echo "Service is not running" && printf '\n%s\n' "Attempting to start rsyslog service ....";
      sudo service rsyslog start >/dev/null
    then
      ps -C httpd >/dev/null && echo "Running" || echo "Not running"
      read answer
    if $answer is "Running"
      then
        sudo service rsyslog restart >/dev/null && echo "rsyslog service has been restarted"
    else 
      if $answer is "Not Running"
        then
          sudo systemctl list-unit-files | grep rsyslog
          echo "Does it show as 'masked'? Type Yes or No, followed by [ENTER]:"
          read masked
            if $masked is "Yes"
              then
                sudo systemctl unmask rsyslog
                sudo service rsyslog start
            else
              if $masked is "No"
                then
                  sudo service rsyslog start && ps -C httpd >/dev/null && echo "Running" || echo "Not running"
                  read second_check
                if $second_check is "Not running" 
                  then
                    printf '\n%s\n' "Further diagnostics are required, start with journalctl -xe | grep rsyslog ...."
                else
                  end
                fi
              fi
            fi
        fi
      fi
  #service rsyslog restart
  #exit
  } &> /dev/null
} &> /dev/null

#printf '\n%s\n' "Starting PSAD configuration Installation ......";
#{
# Make manual changes to psad.conf
# sudo nano /etc/psad/psad.conf


#HOME_NET                    $network;
#EXTERNAL_NET                !$HOME_NET;
#IPT_SYSLOG_FILE             /var/log/iptables.log;
#ENABLE_INTF_LOCAL_NETS         N;
#EXPECT_TCP_OPTIONS             Y;

############################################################
# FWSNORT
############################################################

#sudo nano /etc/fwsnort/fwsnort.conf

#UPDATE_RULES_URL        http://rules.emergingthreats.net/open/snort-edge/emerging-all.rules;
#UPDATE_RULES_URL        http://rules.emergingthreats.net/fwrules/emerging-IPTABLES-ALL.rules;
#UPDATE_RULES_URL        http://rules.emergingthreats.net/open/snort-2.9.0/emerging-all.rules;

#sudo sed -i '18748 s/^/#/' /var/lib/fwsnort/fwsnort.save

#sudo /var/lib/fwsnort/fwsnort.sh

#fwsnort --update-rules

#fwsnort -N --ipt-sync
#} &> /dev/null
