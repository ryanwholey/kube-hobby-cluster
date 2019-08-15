#!/usr/bin/env bash
pushd terraform2
terraform apply -var-file="secrets.tfvars" -auto-approve