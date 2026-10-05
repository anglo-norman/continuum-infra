# Phase 1.2 - RDS Postgres, originally created by CloudFormation
# (cloudformation/rds-postgres.yaml) and adopted into Terraform via the
# import blocks in imports.tf.
#
# Derived from `terraform plan -generate-config-out`, then cleaned:
#   - removed all domain_* attributes (Active Directory join; not used here,
#     and domain_dns_ips = [] fails the provider's own MinItems:2 validation,
#     which is what broke the first generation attempt)
#   - removed tags_all (computed: tags + provider default_tags)
#   - removed password / password_wo / password_wo_version (conflict with
#     manage_master_user_password)
#   - set manage_master_user_password = true (generator emitted null, but the
#     instance genuinely has an RDS-managed Secrets Manager secret)
#   - removed iops / storage_throughput (gp3 defaults for this size; left
#     computed so AWS owns them)
#   - removed null-valued optional attributes that were pure noise
#
# Tags initially said ManagedBy = "cloudformation" to match live truth so the
# post-import plan came out clean. After the CloudFormation stack was deleted
# with DeletionPolicy: Retain, that label became inaccurate - these are now
# Terraform-managed, so the tags were flipped to "terraform" as the first
# deliberate change proving sole ownership.

resource "aws_db_subnet_group" "postgres" {
  description = "Continuum Postgres - private subnets only"
  name        = "continuum-rds-dbsubnetgroup-cdsaqm7dwjlc"
  subnet_ids  = ["subnet-04847763db4b547b3", "subnet-0a27ba3ea9e406a10"]

  tags = {
    ManagedBy = "terraform"
    Name      = "continuum-db-subnet-group"
    Project   = "continuum"
  }
}

resource "aws_security_group" "postgres" {
  name        = "continuum-rds-DBSecurityGroup-1tjIXT8bt3kj"
  description = "Continuum Postgres - inbound 5432 from inside the VPC only"
  vpc_id      = "vpc-08bcebfa26418e6f4"

  ingress = [{
    cidr_blocks      = ["10.50.0.0/16"]
    description      = "Postgres from within the VPC"
    from_port        = 5432
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "tcp"
    security_groups  = []
    self             = false
    to_port          = 5432
  }]

  egress = [{
    cidr_blocks      = ["0.0.0.0/0"]
    description      = ""
    from_port        = 0
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "-1"
    security_groups  = []
    self             = false
    to_port          = 0
  }]

  tags = {
    ManagedBy = "terraform"
    Name      = "continuum-db-sg"
    Project   = "continuum"
  }
}

resource "aws_db_instance" "postgres" {
  identifier     = "continuum-postgres"
  engine         = "postgres"
  engine_version = "18.6"
  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true
  kms_key_id        = "arn:aws:kms:us-east-1:458781646101:key/d65d8973-da30-4da9-8a99-5b52c44bb8e8"

  db_name  = "continuum"
  username = "continuumadmin"
  port     = 5432

  # RDS owns the password in Secrets Manager; Terraform never sees it.
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.postgres.name
  vpc_security_group_ids = [aws_security_group.postgres.id]
  publicly_accessible    = false
  network_type           = "IPV4"
  availability_zone      = "us-east-1b"
  multi_az               = false

  parameter_group_name     = "default.postgres18"
  option_group_name        = "default:postgres-18"
  engine_lifecycle_support = "open-source-rds-extended-support"
  database_insights_mode   = "standard"

  backup_retention_period  = 0
  backup_window            = "05:23-05:53"
  backup_target            = "region"
  delete_automated_backups = true
  copy_tags_to_snapshot    = false
  maintenance_window       = "wed:03:09-wed:03:39"

  auto_minor_version_upgrade = true
  ca_cert_identifier         = "rds-ca-rsa2048-g1"
  deletion_protection        = false
  dedicated_log_volume       = false
  customer_owned_ip_enabled  = false

  iam_database_authentication_enabled   = false
  monitoring_interval                   = 0
  performance_insights_enabled          = false
  performance_insights_retention_period = 0
  max_allocated_storage                 = 0
  enabled_cloudwatch_logs_exports       = []

  # Terraform-only concept with no AWS counterpart, so config generation
  # cannot infer it. Without this, `terraform destroy` refuses to run
  # without a final_snapshot_identifier.
  skip_final_snapshot = true

  tags = {
    ManagedBy = "terraform"
    Name      = "continuum-postgres"
    Project   = "continuum"
  }
}
