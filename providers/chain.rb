#
# Cookbook Name:: iptables-ng
# Provider:: chain
#
# Copyright 2012, Chris Aumann
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
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

require 'date'

action :create do
  edit_chain(:create)
end

action :create_if_missing do
  edit_chain(:create_if_missing)
end

action :delete do
  edit_chain(:delete)
end

def edit_chain(exec_action)
  # only default chains can have a policy
  policy =
    if %w(INPUT OUTPUT FORWARD PREROUTING POSTROUTING).include?(new_resource.chain)
      new_resource.policy
    else
      '- [0:0]'
    end

  chain_path = "/etc/iptables.d/#{new_resource.table}/#{new_resource.chain}/default"

  directory ::File.dirname(chain_path) do
    owner  'root'
    group  node['root_group']
    mode   0o700
    not_if { exec_action == :delete }
  end

  # Generating a random resource identifier, to workaround Chef cloning issues.
  file "#{chain_path}-#{DateTime.now.to_time.to_i}-#{rand(100_000)}" do
    path     chain_path
    owner    'root'
    group    node['root_group']
    mode     0o600
    content  "#{policy}\n"
    notifies :run, 'ruby_block[create_rules]', :delayed
    notifies :run, 'ruby_block[restart_iptables]', :delayed
    action   exec_action
  end
end
