#!/usr/bin/env ruby

require 'facter'

@chkconfig = "/sbin/chkconfig"
@status = "/sbin/status"

@services = {   "mysql" => "mysql|mysqld", "nagios" => "nagios", "ssh" => "sshd", "munin-node" => "munin-node", "spamassassin" => "spamassassin", "ntp" => "ntpd", "ctasd" => "ctasd",
                "bind" => "named", "postfix" => "postfix", "nrpe" => "nrpe", "apache" => "httpd", "cron" => "crond", "snmp" => "snmpd", "puppet" => "puppet", "ctipd" => "ctipd",
                "mcollective" => "mcollective", "activemq" => "activemq", "postfix" => "postfix", "storman" => "stor_agent", "hobbit" => "hobbit-client", "syslog" => "syslog", "rbldns" => "rbldnsd",
                "clamav" => "clamd", "haproxy" => "haproxy", "jboss" => "jboss_init_redhat", "monit" => "monit", "openmanage" => "dsm_om_shrsvc" }

@apache_modules = [ "passenger" ]

def check_init(service)
    return %x[if [ "$(#{@chkconfig} --list #{service} 2> /dev/null | grep $(runlevel | awk '{ print $2 }'):on)" != "" ]; then echo 0; else echo 1; fi].chomp.to_i
end

def check_upstart(service)
    return %x[if [ "$(#{@status} #{service} 2> /dev/null | grep 'start/')" != "" ]; then echo 0; else echo 1; fi].chomp.to_i
end

def check_service(services)
    services.split("|").each { |service|
        if (check_init(service) == 0 or check_upstart(service) == 0)
            return 0
        end
    }

    return 1
end

def check_apache_module(mod)
    return %x[/usr/sbin/httpd -M 2>&1 | grep #{mod} | wc -l].chomp.to_i
end

fact_services = Array.new

@services.each { |service, value| fact_services << service if check_service(value) == 0 }
@apache_modules.each { |mod| fact_services << mod if check_apache_module(mod) >= 1 }

Facter.add("services") do
    setcode do
        fact_services.sort.join(",")
    end
end
