#!/usr/bin/env bash

pushd terraform2
terraform destroy -var-file="secrets.tfvars" -auto-approve