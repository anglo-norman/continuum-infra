# Phase 1.2 - adopt the CloudFormation-created RDS resources into Terraform.
#
# These import blocks are declarative: `terraform plan -generate-config-out`
# reads the live resources and writes matching config, then `terraform apply`
# performs the actual state import. This file can be deleted once the import
# has been applied - the import blocks are a one-time instruction, not
# ongoing configuration.

import {
  to = aws_db_subnet_group.postgres
  id = "continuum-rds-dbsubnetgroup-cdsaqm7dwjlc"
}

import {
  to = aws_security_group.postgres
  id = "sg-096e47e97a45f6995"
}

import {
  to = aws_db_instance.postgres
  id = "continuum-postgres"
}
