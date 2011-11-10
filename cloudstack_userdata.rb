# cloudstack_userdata.rb:
#
# This script will load the userdata associated with a CloudStack
# guest VM into a collection of puppet facts. It is assumed that
# the userdata is formated as key=value pairs, one pair per line.
# For example, if you set your userdata to "role=foo\nenv=development\n"
# two facts would be created, "role" and "env", with values
# "foo" and "development", respectively. 
#
# A guest VM can get access to its userdata by making an http
# call to its virtual router. We can determine the IP address
# of the virtual router by inspecting the dhcp lease file on 
# the guest VM.
#
# Copyright (C) 2011 Jason Hancock http://geek.jasonhancock.com
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see http://www.gnu.org/licenses/.


require 'facter'

file = '/var/lib/dhclient/dhclient-eth0.leases'

if File.exist?(file) && File.size?(file) != nil 

    cmd = sprintf("/bin/grep dhcp-server-identifier %s | /usr/bin/tail -1 | /bin/awk '{print $NF}' | /usr/bin/tr '\;' ' '", file)
    virtual_router = `#{cmd}`
    virtual_router.strip!

    cmd = sprintf('/usr/bin/wget -q -O - http://%s/latest/user-data', virtual_router)
    result = `#{cmd}`
    
    lines = result.split("\n")

    lines.each do |line|
        if line =~ /^(.+)=(.+)$/
            var = $1; val = $2

            Facter.add(var) do
                setcode { val }
            end
        end
    end
end
