# -----------------------------------------
# Used for TPCC Testing
# -----------------------------------------

my_ip_address = "98.148.51.154"
aws_region_01 = "us-east-2"
owner = "nollen"
project_name = "load-test"
crdb_instance_key_name = "nollen-cockroach-revenue-us-east-2-kp01"
vpc_cidr = "192.168.7.0/24"

# -----------------------------------------
# CRDB Specifications
# -----------------------------------------
crdb_nodes = 3
crdb_instance_type = "m8g.xlarge"
crdb_store_volume_type = "gp3"
crdb_store_volume_size = 600
crdb_version = "25.2.1"
crdb_arm_release = "yes"
crdb_enable_spot_instances = "no"

# HA Proxy
include_ha_proxy = "yes"
haproxy_instance_type = "m6a.xlarge"

# APP Node
include_app = "yes"
app_instance_type = "m6a.xlarge"

create_admin_user = "yes"
admin_user_name = "ron"

