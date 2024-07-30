##############################################################################
# COS Instance with 1 bucket
##############################################################################

# COS Variables
##############################################################################
variable "cos_plan" {
  description = "COS plan type"
  type        = string
  default     = "standard"
}

variable "cos_region" {
  description = "Enter Region for provisioning"
  type        = string
  default     = "global"
}

# COS Service for OpenShift Internal Registry
##############################################################################

resource "ibm_resource_instance" "cos" {
  name              = format("%s-%s", local.basename, "cos")
  service           = "cloud-object-storage"
  plan              = var.cos_plan
  location          = var.cos_region
  resource_group_id = ibm_resource_group.group.id
  tags              = var.tags

  parameters = {
    service-endpoints = "private"
  }
}

## IAM
##############################################################################

resource "ibm_iam_access_group_policy" "policy-cos" {
  access_group_id = ibm_iam_access_group.accgrp.id
  roles           = ["Viewer"]

  resources {
    service           = "cloud-object-storage"
    resource_group_id = ibm_resource_group.group.id
  }
}
