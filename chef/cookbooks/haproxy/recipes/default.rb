package "haproxy" do
  action :install
end

service "haproxy" do
  supports :restart => true
  action [:enable, :start]
end

def fill_instance(port_enum, env_filter)
  inst = {}
  targets = search(:node, "#{env_filter}") || []
  n = targets.first
  inst["admin_port"] = eval("#{port_enum}")
  inst["public_port"] = eval("#{port_enum}")
  inst["nodes"] = {}
  targets.each do |n|
    inst["nodes"][n.fqdn] = {}
    inst["nodes"][n.fqdn]["admin_ip"] = Chef::Recipe::Barclamp::Inventory.get_network_by_type(n, "admin").address
    inst["nodes"][n.fqdn]["public_ip"] = Chef::Recipe::Barclamp::Inventory.get_network_by_type(n, "public").address
    inst["nodes"][n.fqdn]["admin_port"] = eval("#{port_enum}")
    inst["nodes"][n.fqdn]["public_port"] = eval("#{port_enum}")
  end
  inst
end

services = Mash.new

["quantum", "cinder", "glance", "keystone", "swift", "nova"].each do |prop|
  case prop
  when "quantum"
    env_filter = "roles:quantum-server AND roles:quantum-config-#{node[:loadbalancer][:quantum_instance]}"
    port_enum = "n[:quantum][:api][:service_port]"
    services["quantum"] = fill_instance(port_enum, env_filter) if search(:node, "#{env_filter}").size > 0
  when "cinder"
    env_filter = "roles:cinder-controller AND roles:cinder-config-#{node[:loadbalancer][:cinder_instance]}"
    port_enum = "n[:cinder][:api][:bind_port]"
    services["cinder"] = fill_instance(port_enum, env_filter) if search(:node, "#{env_filter}").size > 0
  when "glance"
    env_filter = "roles:glance-server AND roles:glance-config-#{node[:loadbalancer][:glance_instance]}"
    port_enum = "n[:glance][:api][:bind_port]"
    services["glance"] = fill_instance(port_enum, env_filter) if search(:node, "#{env_filter}").size > 0
  when "keystone"
    env_filter = "roles:keystone-server AND roles:keystone-config-#{node[:loadbalancer][:keystone_instance]}"
    services["keystone-api"] = fill_instance("n[:keystone][:api][:api_port]", env_filter) if search(:node, "#{env_filter}").size > 0
    services["keystone-admin"] = fill_instance("n[:keystone][:api][:admin_port]", env_filter) if search(:node, "#{env_filter}").size > 0
    # skip it for the first time, later investigate if service_port is used
    #if fill_instance("n[:keystone][:api][:api_port]", env_filter).admin_port != fill_instance("n[:keystone][:api][:service_port]", env_filter).admin_port
    #  services["keystone-service"] = fill_instance("n[:keystone][:api][:service_port]", env_filter)
    #end
  when "swift"
    env_filter = "roles:swift-proxy AND roles:swift-config-#{node[:loadbalancer][:swift_instance]}"
    port_enum = "8080"
    services["swift-proxy"] = fill_instance(port_enum, env_filter) if search(:node, "#{env_filter}").size > 0
  when "nova"
    env_filter = "roles:nova-multi-controller AND roles:nova-config-#{node[:loadbalancer][:nova_instance]}"
    port_enum = "8774"
    services["nova-api"] = fill_instance(port_enum, env_filter) if search(:node, "#{env_filter}").size > 0
  end
end

public_net_db = data_bag_item('crowbar', 'public_network')
admin_net_db = data_bag_item('crowbar', 'admin_network')
service_name = node[:loadbalancer][:config][:environment]
domain = node[:domain]
public_ip = public_net_db["allocated_by_name"]["#{service_name}.#{domain}"]["address"]
admin_ip = admin_net_db["allocated_by_name"]["#{service_name}.#{domain}"]["address"]


cookbook_file "/etc/default/haproxy" do
  source "haproxy_default"
  owner "root"
  group "root"
  mode 0644
  notifies :restart, resources(:service => "haproxy")
end


template "/etc/haproxy/haproxy.cfg" do
  source "haproxy.cfg.erb"
  owner "root"
  group "root"
  mode 0644
  variables( {
    :admin_ip => admin_ip,
    :public_ip => public_ip,
    :services => services
  } )
  notifies :restart, resources(:service => "haproxy")
end
