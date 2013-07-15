#
# Cookbook Name:: keepalived
# Recipe:: default
#
# Copyright 2009, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package "keepalived" do
  action :install
end

service "keepalived" do
  supports :restart => true
  action [:enable, :start]
end

env_filter = "roles:#{node[:loadbalancer][:config][:environment]}"
if node[:roles].include?("lb-master")
  env_filter = "#{env_filter} AND roles:lb-slave"
  is_master = true
else
  env_filter = "#{env_filter} AND roles:lb-master"
  is_master = false
end

neighbor = search(:node, "#{env_filter}").first || []
admin_net = Chef::Recipe::Barclamp::Inventory.get_network_by_type(node, "admin")
public_net = Chef::Recipe::Barclamp::Inventory.get_network_by_type(node, "public")
admin_iface = admin_net.interface
public_iface = public_net.interface
public_net_db = data_bag_item('crowbar', 'public_network')
admin_net_db = data_bag_item('crowbar', 'admin_network')
service_name = node[:loadbalancer][:config][:environment]
domain = node[:domain]
public_ip = public_net_db["allocated_by_name"]["#{service_name}.#{domain}"]["address"]
admin_ip = admin_net_db["allocated_by_name"]["#{service_name}.#{domain}"]["address"]

node.set["loadbalancer"]["public_ip"] = public_ip
node.set["loadbalancer"]["admin_ip"] = admin_ip
#lets leave here an entity for hosts wich may be helpfull when we going to introduce ssl support for lb
node.set["loadbalancer"]["public_host"] = "public.#{service_name}.#{domain}"
node.set["loadbalancer"]["admin_host"] = "#{service_name}.#{domain}"

node.save

template "/etc/keepalived/keepalived.conf" do
  source "keepalived.conf.erb"
  owner "root"
  group "root"
  mode 0644
  variables( {
    :is_master => is_master,
    :admin_iface => admin_iface,
    :admin_ip => admin_ip,
    :public_iface => public_iface,
    :public_ip => public_ip
  } )
  notifies :restart, resources(:service => "keepalived")
end
