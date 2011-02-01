#!/usr/bin/env ruby

require 'facter'
interfaces = %x[/usr/bin/facter | grep 'network_' | cut -d= -f1 | cut -d_ -f2,3,4]

Facter.add("interfaces") do
    setcode do
        interfaces.split(" \n").join(",")
    end
end
