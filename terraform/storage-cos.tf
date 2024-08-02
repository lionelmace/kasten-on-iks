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

## COS Bucket for Kasten
##############################################################################
resource "ibm_cos_bucket" "kasten-bucket" {
  bucket_name           = format("%s-%s", local.basename, "kasten-bucket")
  resource_instance_id  = ibm_resource_instance.cos.id
  storage_class         = "smart"

  # Key management services can only be added during bucket creation.
  # depends_on           = [ibm_iam_authorization_policy.iam-auth-kms-cos]
  # kms_key_crn          = ibm_kms_key.key.id

  cross_region_location = "eu"
  endpoint_type = "public"
  # endpoint_type = "private"
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
