# Import references to some of the existing default VPC and subnet values.
# Obviously, real world applications should never use these!

data "aws_availability_zones" "available" {}

data "aws_vpc" "selected" {
  default = true
}

data "aws_subnet" "selected" {
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
  vpc_id            = "${data.aws_vpc.selected.id}"
  default_for_az    = true
}

data "aws_security_group" "selected" {
  name   = "default"
  vpc_id = "${data.aws_vpc.selected.id}"
}
