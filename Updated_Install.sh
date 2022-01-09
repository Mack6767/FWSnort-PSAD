#Starting again from scratch, kinda, through trial and horrible error I've been able to reliably get it to work... sorta

#WARNING: RUN AS ROOT SUDO DOES NOT WORK AS EXPECTED.

#even though the installer is suppose to install these modules automatically I've found it doesn't always, just a verification step soley for psad

cpanm NetAddr::IP
cpanm Date::Calc
cpanm Unix::Syslog
cpanm Bit::Vector
cpanm IPTables::Parse
cpanm IPTables::ChainMgr
cpanm Storable

printf '\n%s\n' "Locking the shite down!...";
{
echo "Would you like to install FWSnort? Please type Yes or No, followed by [ENTER]";
read install
if [[ $install == "Yes" ]]; then
  printf '\n%s\n' "Starting UFW and GUFW Installation and configuring for FWSnort with PSAD ......"; 
    {
      echo "First things first, installing from repository"
      apt update -y && apt upgrade -y && apt install fwsnort -y
      echo "Downloading the latest git for fwsnort:"
      cd /home/$USER/Downloads/ && git clone https://github.com/mrash/fwsnort.git
      # cd /home/mack/Downloads/fwsnort/ && perl /home/mack/Downloads/fwsnort/install.pl
      nano /etc/fwsnort/fwsnort.conf
      
      #Add the following two lines to UPDATE_RULES_URL:
      
      UPDATE_RULES_URL        http://rules.emergingthreats.net/open/snort-edge/emerging-all.rules;
      UPDATE_RULES_URL        http://rules.emergingthreats.net/fwrules/emerging-IPTABLES-ALL.rules;
      
      fwsnort --update-rules && fwsnort -N --ipt-sync --no-ipt-comments && /var/lib/fwsnort/fwsnort.sh
    } &> /home/${USER}/Documents/ufw_install.log
elseif [[ $install == "No" ]]; then

cd /home/mack/Downloads/psad/ && perl /home/mack/Downloads/psad/install.pl



iptables -A INPUT -j LOG
iptables -A OUTPUT -j LOG
iptables -A FORWARD -j LOG
iptables -N PSAD_BLOCK_INPUT
iptables -N PSAD_BLOCK_OUTPUT
iptables -N PSAD_BLOCK_FORWARD
iptables -A OUTPUT -j PSAD_BLOCK_OUTPUT
iptables -A INPUT -j PSAD_BLOCK_INPUT
iptables -A FORWARD -j PSAD_BLOCK_FORWARD



psad --sig-update && psad -H && psad --gnuplot-interactive --fw-list-auto --fw-include-ips
