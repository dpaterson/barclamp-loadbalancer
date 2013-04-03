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

   #
  def create_proposal
    @logger.debug("Nova create_proposal: entering")
    base = super

    base
  end

  def form_virt_node_name(prop_name)
    "virt-#{prop_name}"
  end

  def apply_role_pre_chef_call(old_role, role, all_nodes)
    name =""
    role.override_attributes["loadbalancer"]["config"]["environment"].scan(/.*-.*-(.*)$/) { |x| 
      name = x
    }
    vnodes = NodeObject.find_nodes_by_name(form_virt_node_name(name))
    if vnodes.nil? or vnodes.length <1 
      vnode = NodeObject.create_new name
    else
      vnode=vnodes[0]
    end

    net_svc = NetworkService.new @logger
    # create a new public IP address for the virtual node.
    net_svc.allocate_ip "default", "public", "host", vnode
  end

end

