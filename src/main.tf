module "network" {
  source  = "../modules/network"
  cluster = terraform.workspace
}
