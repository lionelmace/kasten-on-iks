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

## Service Credentials
##############################################################################
resource "ibm_resource_key" "cos-hmac-kasten" {
  name                 = format("%s-%s", local.basename, "cos-kasten-key")
  resource_instance_id = ibm_resource_instance.cos.id
  role                 = "Writer"
  parameters           = { HMAC = true }
}

locals {
  endpoints = [
    {
      name        = "kasten",
      # cos_endpoint = nonsensitive(ibm_resource_key.cos-hmac-kasten.credentials["connection.postgres.authentication.username"])
      cos_access_key_id = nonsensitive(ibm_resource_key.cos-hmac-kasten.credentials["cos_hmac_keys.access_key_id"])
      cos_secret_access_key = nonsensitive(ibm_resource_key.cos-hmac-kasten.credentials["cos_hmac_keys.secret_access_key"])
      cos_endpoint = ibm_cos_bucket.kasten-bucket.s3_endpoint_direct
    }
  ]
}

# locals {
#   account_id = data.ibm_iam_account_settings.account_settings.account_id
# }

output "cos-credentials" {
  value = local.endpoints
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
