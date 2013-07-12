# Copyright 2012, Dell 
# 
# Licensed under the Apache License, Version 2.0 (the "License"); 
# you may not use this file except in compliance with the License. 
# You may obtain a copy of the License at 
# 
#  http://www.apache.org/licenses/LICENSE-2.0 
# 
# Unless required by applicable law or agreed to in writing, software 
# distributed under the License is distributed on an "AS IS" BASIS, 
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
# See the License for the specific language governing permissions and 
# limitations under the License. 
# 

class LoadbalancerService < ServiceObject
  def initialize(thelogger)
    @logger = thelogger
    @bc_name = "loadbalancer"
  end

  def proposal_dependencies(role)
    answer = []
    #lets skip for now rabbitmq and database, its doubtly that someone will add HA for this components quickly enought
    #deps = ["quantum", "cinder", "glance", "keystone", "swift", "nova"]
    #deps << "git" if role.default_attributes[@bc_name]["use_gitrepo"]
    #deps.each do |dep|
    #  answer << { "barclamp" => dep, "inst" => role.default_attributes[@bc_name]["#{dep}_instance"] }
    #end
    answer
  end


   #
  def create_proposal
    @logger.debug("Loadbalancer create_proposal: entering")
    base = super
    
    ["Quantum", "Cinder", "Glance", "Keystone", "Swift", "Nova"].each do |inst|
      base["attributes"][@bc_name]["#{inst.downcase}_instance"] = ""
      begin
        instService = eval "#{inst}Service.new(@logger)"
        instes = instService.list_active[1]
        if instes.empty?
          # No actives, look for proposals
          instes = instService.proposals[1]
          instes = []
        end
        base["attributes"][@bc_name]["#{inst.downcase}_instance"] = instes[0] unless instes.empty?
      rescue
        @logger.info("#{@bc_name} create_proposal: no #{inst.downcase} found")
      end
    end
    base
  end

  def form_virt_node_name(prop_name)
    "virt-#{prop_name}"
  end

  def apply_role_pre_chef_call(old_role, role, all_nodes)
    net_svc = NetworkService.new @logger
    #all nodes need a public iface to anounce public endpoint of services and one virtual admin/public
    all_nodes.each do |n|
      net_svc.allocate_ip "default", "public", "host", n
      net_svc.enable_interface "default", "public", n
    end
    if all_nodes.size > 0
      n = NodeObject.find_node_by_name all_nodes.first
      @logger.info("cfg=#{role.name}")
      @logger.info("domain=#{n[:domain]}")
      service_name=role.name
      domain=n[:domain]
      # allocate new public ip address for the virtual node
      net_svc.allocate_virtual_ip "default", "public", "host", "#{service_name}.#{domain}"
      # allocate new admin ip for the virtual node
      net_svc.allocate_virtual_ip "default", "admin", "host", "#{service_name}.#{domain}"
    end
  end
end
