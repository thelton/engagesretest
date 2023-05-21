variable "cidr" {
  type = string
  description = "Cidr range for VPC"
  default = "10.50.0.0/16"
}

variable "azs" {
  type        = list(string)
  description = "List of AZs to use"
  default     = ["us-east-1a", "us-east-1b"]
}

variable "private_subnets" {
  type        = list(string)
  description = "List of Cidr ranges for Private Subnet"
  default     = ["10.50.1.0/24", "10.50.2.0/24"]
}

variable "database_subnets" {
  type        = list(string)
  description = "List of Cidr ranges for DB"
  default     = ["10.50.10.0/24", "10.50.20.0/24"]
}

variable "public_subnets" {
  type        = list(string)
  description = "List of Cidr ranges for Public Subnet"
  default     = ["10.50.101.0/24", "10.50.102.0/24"]
}