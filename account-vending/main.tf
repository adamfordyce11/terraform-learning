# Define the main Control Tower resources
module "control_tower_landing_zone" {
  source  = "terraform-aws-modules/control-tower/aws"
  version = "1.1.0"

  # Control Tower configuration options
  landing_zone_name = var.landing_zone_name
  organizational_unit_id = var.organizational_unit_id
  log_archive_bucket_name = var.log_archive_bucket_name
  security_account_id = var.security_account_id
  security_account_region = var.security_account_region
  log_archive_account_id = var.log_archive_account_id
  enable_guardduty = true
  enable_config = true
  enable_config_aggregator = true
  config_aggregator_account_id = var.config_aggregator_account_id
  config_aggregator_region = var.config_aggregator_region
  enable_cloudtrail = true
  cloudtrail_account_id = var.cloudtrail_account_id
  cloudtrail_region = var.cloudtrail_region
  enable_aws_sso = true
  enable_single_sign_on = true
  create_sample_users = true
  enable_account_factory = true
  enable_account_vending_machine = true
  enable_orchestration = true
  enable_sns_notifications = true
  create_example_organizational_units = true
  create_example_policies = true
}

# Define the Account Factory resource
module "control_tower_account_factory" {
  source  = "terraform-aws-modules/control-tower/aws//modules/account-factory"
  version = "1.1.0"

  # Control Tower configuration options
  landing_zone_id = module.control_tower_landing_zone.landing_zone_id
  organizational_unit_id = var.organizational_unit_id
  account_factory_name = var.account_factory_name
  enabled = true
  cloudtrail_bucket_name = var.cloudtrail_bucket_name

  # Account creation options
  account_creation_role_name = "AccountCreationRole"
  account_creation_role_path = "/"
  account_creation_email_suffix = "@${var.account_name_prefix}.example.com"
  default_sns_topic_name = "${var.landing_zone_name}-AccountCreated"
  default_sns_topic_subject = "New Account Created"
  default_sns_topic_message = "A new account has been created"
  supported_regions = ["us-east-1", "us-west-2"]
  default_tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# Define the Account Vending Machine resource
module "control_tower_account_vending_machine" {
  source  = "terraform-aws-modules/control-tower/aws//modules/account-vending-machine"
  version = "1.1.0"

  # Control Tower configuration options
  landing_zone_id = module.control_tower_landing_zone.landing_zone_id
  account_factory_id = module.control_tower_account_factory.account_factory_id
  organizational_unit_id = var.organizational_unit_id
  account_vending_machine_name = var.account_vending_machine_name
  enabled = true
  create_accounts_iam_role_name = "CreateAccountsRole"

  # Vending configuration options
  vending_users = [
    {
      name           = "vending-user"
      password       = "change_me"
      access_key     = "your-access-key"
      secret_key     = "your-secret-key"
      policy_arns    = ["arn:aws:iam::aws:policy/AWSCloudFormationReadOnlyAccess"]
      groups         = ["vending-users"]
    }
  ]

  # Account creation options
  default_account_name = "${var.account_name_prefix}-account"
  default_account_email = "${var.account
  default_account_policy_arns = ["arn:aws:iam::aws:policy/AdministratorAccess"]
  default_account_tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# Define the Service Role resource
module "control_tower_service_role" {
  source  = "terraform-aws-modules/iam/aws//modules/role"
  version = "4.0.0"

  # Role configuration options
  name_prefix = var.service_role_name_prefix
  path = "/"
  description = "Service role used by Control Tower"

  # Assume role policy configuration
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "ec2.amazonaws.com"
            "codedeploy.amazonaws.com"
            "elasticloadbalancing.amazonaws.com"
          ]
        }
      }
    ]
  })

  # Permissions policy configuration
  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/AWSCodeDeployFullAccess",
    "arn:aws:iam::aws:policy/AmazonECS_FullAccess",
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess",
    "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
  ]
}

# Define the Service User resource
module "control_tower_service_user" {
  source  = "terraform-aws-modules/iam/aws//modules/user"
  version = "4.0.0"

  # User configuration options
  name = var.service_user_name
  path = "/"
  tags = {
    Terraform   = "true"
    Environment = "dev"
  }

  # Permissions policy configuration
  policy_arns = [
    "arn:aws:iam::aws:policy/AdministratorAccess",
    module.control_tower_account_factory.account_creation_policy_arn
  ]
}

# Attach the Service Role and User policies to the Service User
module "control_tower_service_user_policy_attachment" {
  source  = "terraform-aws-modules/iam/aws//modules/user-policy-attachment"
  version = "4.0.0"

  # Policy attachment configuration
  user_name = module.control_tower_service_user.user_name
  policy_arns = [
    module.control_tower_service_role.policy_arn,
    module.control_tower_account_factory.account_creation_policy_arn
  ]
}

# Define the Project Role resource
module "control_tower_project_role" {
  source  = "terraform-aws-modules/iam/aws//modules/role"
  version = "4.0.0"

  # Role configuration options
  name_prefix = var.project_role_name_prefix
  path = "/"
  description = "Role used by project teams to manage AWS resources"

  # Assume role policy configuration
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = [
            module.control_tower_service_user.user_arn,
            "arn:aws:iam::${var.account_id}:root"
          ]
        }
      }
    ]
  })

  # Permissions policy configuration
  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess",
    "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
  ]
}

# Define the Infrastructure Role resource
module "control_tower_infrastructure_role" {
  source  = "terraform-aws-modules/iam/aws//modules/role"
  version = "4.0.0"

  # Role configuration options
  name_prefix = var.infrastructure_role_name_prefix
  path = "/"
  description = "Role used by instances and other resources to access AWS services and resources"

  # Assume role policy configuration
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  # Permissions policy configuration
  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess",
    "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
  ]
}

# Define the Terraform workspace resources for each account
module "terraform_workspace" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/terraform-workspace"
  version = "2.2.0"

  # Workspace configuration options
  account_ids = module.control_tower_account_factory.account_ids
  prefix      = var.terraform_workspace_prefix
  delimiter   = "-"
}

# Attach permissions policies to the Service User and Project Role
module "control_tower_project_role_policy_attachment" {
  source  = "terraform-aws-modules/iam/aws//modules/role-policy-attachment"
  version = "4.0.0"

  # Policy attachment configuration
  role_name = module.control_tower_project_role.role_name
  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess",
    "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
  ]
}

module "control_tower_service_user_policy_attachment2" {
  source  = "terraform-aws-modules/iam/aws//modules/user-policy-attachment"
  version = "4.0.0"

  # Policy attachment configuration
  user_name = module.control_tower_service_user.user_name
  policy_arns = [
    module.control_tower_project_role.policy_arn,
    module.control_tower_infrastructure_role.policy_arn,
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess",
    "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
  ]
}

# Define the Control Tower resources
module "control_tower" {
  source  = "terraform-aws-modules/control-tower/aws"
  version = "1.1.0"

  # Control Tower configuration options
  organization_admin_account_id    = var.organization_admin_account_id
  service_role_arn                 = module.control_tower_service_role.role_arn
  service_user_name                = module.control_tower_service_user.user_name
  project_role_arn_prefix          = module.control_tower_project_role.role_arn_prefix
  infrastructure_role_arn          = module.control_tower_infrastructure_role.role_arn
  default_account_vending_machine_policy_arn = module.control_tower_account_factory.account_vending_policy_arn
  default_account_policy_arns      = var.default_account_policy_arns
  default_account_tags             = var.default_account_tags
  terraform_workspace_prefix       = module.terraform_workspace.prefix
  terraform_workspace_account_ids  = module.terraform_workspace.account_ids
}

