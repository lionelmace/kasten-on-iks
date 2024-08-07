##############################################################################
# Kubernetes cluster
##############################################################################


# Kubernetes Variables
##############################################################################

variable "iks_cluster_name" {
  description = "name for the iks cluster"
  default     = "kasten-iks-cluster"
}

variable "iks_version" {
  description = "Specify the Kubernetes version, including the major.minor version. To see available versions, run `ibmcloud ks versions`."
  type        = string
  default     = ""
}

variable "iks_machine_flavor" {
  description = "The flavor of VPC worker node to use for your cluster. Use `ibmcloud ks flavors` to find flavors for a region."
  type        = string
  default     = "bx2.4x16"
}

variable "iks_worker_nodes_per_zone" {
  description = "Number of workers to provision in each subnet"
  type        = number
  default     = 1
}

variable "iks_wait_till" {
  description = "To avoid long wait times when you run your Terraform code, you can specify the stage when you want Terraform to mark the cluster resource creation as completed. Depending on what stage you choose, the cluster creation might not be fully completed and continues to run in the background. However, your Terraform code can continue to run without waiting for the cluster to be fully created. Supported args are `MasterNodeReady`, `OneWorkerNodeReady`, and `IngressReady`"
  type        = string
  default     = "OneWorkerNodeReady"

  validation {
    error_message = "`iks_wait_till` value must be one of `MasterNodeReady`, `OneWorkerNodeReady`, or `IngressReady`."
    condition = contains([
      "MasterNodeReady",
      "OneWorkerNodeReady",
      "IngressReady"
    ], var.iks_wait_till)
  }
}

variable "iks_force_delete_storage" {
  description = "force the removal of persistent storage associated with the cluster during cluster deletion."
  type        = bool
  default     = true
}

variable "iks_update_all_workers" {
  description = "Kubernetes version of the worker nodes is updated."
  type        = bool
  default     = true
}

variable "iks_disable_public_service_endpoint" {
  description = "Boolean value true if Public service endpoint to be disabled."
  type        = bool
  default     = false
}

## Resources
##############################################################################
resource "ibm_container_vpc_cluster" "iks_cluster" {
  name              = format("%s-%s", local.basename, var.iks_cluster_name)
  vpc_id            = ibm_is_vpc.vpc.id
  resource_group_id = ibm_resource_group.group.id
  # Optional: Specify Kubes version. If not included, default version is used
  kube_version         = var.iks_version == "" ? null : var.iks_version
  tags                 = var.tags
  update_all_workers   = var.iks_update_all_workers
  force_delete_storage = var.iks_force_delete_storage

  flavor                          = var.iks_machine_flavor
  worker_count                    = var.iks_worker_nodes_per_zone
  wait_till                       = var.iks_wait_till
  disable_public_service_endpoint = var.iks_disable_public_service_endpoint
  # By default, public outbound access is blocked in IKS 1.30
  # Commented because only supported as of IKS 1.30
  # disable_outbound_traffic_protection = true


  dynamic "zones" {
    for_each = { for subnet in ibm_is_subnet.subnet : subnet.id => subnet }
    content {
      name      = zones.value.zone
      subnet_id = zones.value.id
    }
  }

  kms_config {
    instance_id      = ibm_resource_instance.key-protect.guid # GUID of Key Protect instance
    crk_id           = ibm_kms_key.key.key_id                 # ID of customer root key
    private_endpoint = true
  }
}