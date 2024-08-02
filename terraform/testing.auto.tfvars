##############################################################################
## Global Variables
##############################################################################

#region     = "eu-de"     # eu-de for Frankfurt MZR

##############################################################################
## VPC
##############################################################################
vpc_classic_access            = false
vpc_address_prefix_management = "manual"
vpc_enable_public_gateway     = true


##############################################################################
## Cluster IKS
##############################################################################
iks_version               = "1.29.7"
iks_worker_nodes_per_zone = 1
iks_machine_flavor        = "bx2.4x16"

# Possible values: MasterNodeReady, OneWorkerNodeReady, or IngressReady
iks_wait_till          = "IngressReady"
iks_update_all_workers = true
# iks_worker_nodes_per_zone = 2

##############################################################################
## COS
##############################################################################
cos_plan   = "standard"
cos_region = "global"