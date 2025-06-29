variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "app_name" {
  description = "Name of the application"
  type        = string
  default     = "api"
}

variable "scan_on_push" {
  description = "Indicates whether images are scanned after being pushed to the repository"
  type        = bool
  default     = false // should be true but I am a cheap ass
}

variable "force_delete" {
  description = "If true, will delete the repository even if it contains images. Defaults to false."
  type = bool
  default = true
}