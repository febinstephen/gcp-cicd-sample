variable "project_id" {
  description = "The ID of the Google Cloud project"
  type        = string
}

variable "region" {
  description = "The region where resources will be created"
  type        = string
  default     = "northamerica-northeast1"
}

variable "zones" {
  description = "The zones where resources will be created"
  type        = list(string)
  default     = ["northamerica-northeast1-a", "northamerica-northeast1-b", "northamerica-northeast1-c"]
}
