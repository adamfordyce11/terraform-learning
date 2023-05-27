
module "instance" {
  source        = "../modules/instance"
  count         = var.num_instances
  instance_type = var.instance_type
  instance_num  = count.index
  name          = "${var.name}-${count.index}"
  account       = var.account
  environment   = var.environment
  service       = var.service
  region        = var.region
  network       = var.network
  ami           = var.ami
  vpc_id        = data.aws_vpc.current_vpc.id
  azs           = var.azs
}