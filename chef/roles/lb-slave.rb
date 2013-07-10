name "lb-slave"
description "Floating IP active/passive IP service HA provider"
run_list(
   "recipe[chef-keepalived::default]",
   "recipe[chef-keepalived::ip_nonlocal_bind]",
   "recipe[haproxy::default]"
)
default_attributes(
)
override_attributes()

