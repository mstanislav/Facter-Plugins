#!/usr/bin/env ruby

require 'facter'

@facter = "/usr/bin/facter"
@chkconfig = "/sbin/chkconfig"
@status = "/sbin/status"

exit unless File.exists?(@facter) and File.exists?(@chkconfig)

@distro = Facter.value('lsbdistid')

exit unless @distro.match(/Ubuntu|RedHatEnterprise|CentOS/)

@services = {   "Ubuntu" => {   "mysql" => "mysql", "nagios" => "nagios3", "ssh" => "ssh", "munin-node" => "munin-node", "spamassassin" => "spamassassin", "ntp" => "ntp",
                                "bind" => "bind9", "postfix" => "postfix", "nrpe" => "nagios-nrpe-server", "apache" => "apache2", "cron" => "cron", "snmp" => "snmpd", "puppet" => "puppet",
                                "mcollective" => "mcollective" },
                "CentOS" => {   "mysql" => "mysqld", "nagios" => "nagios", "ssh" => "sshd", "munin-node" => "munin-node", "spamassassin" => "spamassassin", "ntp" => "ntpd",
                                "bind" => "named", "postfix" => "postfix", "nrpe" => "nrpe", "apache" => "httpd", "cron" => "crond", "snmp" => "snmpd", "puppet" => "puppet",
                                "mcollective" => "mcollective" },
}

def check_init(service)
    return %x[if [ "$(#{@chkconfig} --list #{service} 2> /dev/null | grep $(runlevel | awk '{ print $2 }'):on)" != "" ]; then echo 0; else echo 1; fi].chomp.to_i
end

def check_upstart(service)
    return %x[if [ "$(#{@status} #{service} 2> /dev/null | grep 'start/')" != "" ]; then echo 0; else echo 1; fi].chomp.to_i
end

def check_service(service)
    if @services[@distro].has_value?(service) and (check_init(service) == 0 or check_upstart(service) == 0)
        return 0
    else
        return 1
    end
end

fact_services = Array.new

@services[@distro].each { |service, value| fact_services << service if check_service(value) == 0 }

Facter.add("services") do
    setcode do
        fact_services.sort.join(",")
    end
end
