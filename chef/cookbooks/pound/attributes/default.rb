default[:pound][:ssl_port] = 443
default[:pound][:ssl_proxy_port] = 81

default["loadbalancer"]["services"] = [
            { "service_type" : "swift",
              "service_instance" : "default",
              "ssl" : true,
              "external_port" : 8080
            }
]

default["loadbalancer"]["params"] = {
    :user => "www-data",
    :group => "www-data",
    :loglevel => 1,
    :alive_timeout =>30
}

### 
# Crowbar would set these based on the services used.
default["loadbalancer"]["backend"] = [
    { :address =>"192.168.124.81", :port => 8080 },
    { :address =>"192.168.124.82", :port => 8080 } 
]

default["loadbalancer"]["listen"] = {
    :address => "192.168.124.83",
    :port =>80
}

default["node"]["keepalived"]["vrrp_instances"]= [
  { 
    :nopreempt          => false,     # omitted if false, included if true
    :advert_int         => nil, # Advertisement Interval (in seconds)
    :virtual_router_id  => 51,
    :master_priority    => 101,     # Priority to use on the Master
    :backup_priority    => 100,     # Priority to use on the Backup
    :backup_nodes       => [], # node names for backup hosts. These will
    :virtual_ipaddress  => ["127.0.0.1"],
  }
]
