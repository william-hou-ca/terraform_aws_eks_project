variable "my_ip" {
  type = list(string)
  description = "Define your work public ip range autorized to access aws service"
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type = string
}

variable "db_name" {
  type = string
}