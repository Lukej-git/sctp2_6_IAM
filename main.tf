module "db_reader" {
source = "./modules/db_reader"
name_prefix = "luke-tf2-6"
instance_type = "t2.micro"
instance_count = 1
vpc_id = "vpc-012814271f30b4442"
public_subnet = true
alb_listener_arn =""
}