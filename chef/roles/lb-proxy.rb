name "keepalived"
description "Floating IP active/passive IP service HA provider"
run_list(
   "recipe[chef-keepalived::default]"
   "recipe[chef-keepalived::ip_nonlocal_bind]"
   "recipe[pound::default]"
)
default_attributes(
)
override_attributes()

