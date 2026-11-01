terraform {
  required_version = ">= 1.6"
}

variable "name" {
  type    = string
  default = "fixture"
}

resource "terraform_data" "fixture" {
  input = var.name
}

output "name" {
  value = terraform_data.fixture.output
}
