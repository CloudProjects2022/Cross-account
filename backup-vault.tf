resource "aws_kms_key" "backup-key" {
   is_enabled  = true
   policy      = <<POLICY
{
   "Version":"2012-10-17",
   "Statement":[
      {
         "Effect":"Allow",
         "Action":"kms:*",
         "Resource":"*",
         "Principal" : { "AWS" : "arn:aws:iam::<main-account>:root" }
      },
      {
         "Effect":"Allow",
         "Action": [ 
            "kms:DescribeKey",
            "kms:Encrypt",
            "kms:Decrypt",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey",
            "kms:GenerateDataKeyWithoutPlaintext"
        ],
         "Resource":"*",
         "Principal" : { "AWS" : "arn:aws:iam::<replication-account>:root" }
      },
      {
         "Effect":"Allow",
         "Action": [ 
            "kms:CreateGrant",
            "kms:ListGrants",
            "kms:RevokeGrant"
        ],
         "Resource":"*",
         "Principal" : { "AWS" : "arn:aws:iam::<replication-account>:root" },
         "Condition":{
            "Bool":{
               "kms:GrantIsForAWSResource": true
            }
         }
      }
   ]
}
POLICY              
}

resource "aws_kms_key" "dest-backup-key" {
   is_enabled  = true
   provider = aws.crossbackup
   policy      = <<POLICY
{
   "Version":"2012-10-17",
   "Statement":[
      {
         "Effect":"Allow",
         "Action":"kms:*",
         "Resource":"*",
         "Principal" : { "AWS" : "arn:aws:iam::<replication-account>:root" }
      },
      {
         "Effect":"Allow",
         "Action": [ 
            "kms:DescribeKey",
            "kms:Encrypt",
            "kms:Decrypt",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey",
            "kms:GenerateDataKeyWithoutPlaintext"
        ],
         "Resource":"*",
         "Principal" : { "AWS" : "arn:aws:iam::<main-account>:root" }
      },
      {
         "Effect":"Allow",
         "Action": [ 
            "kms:CreateGrant",
            "kms:ListGrants",
            "kms:RevokeGrant"
        ],
         "Resource":"*",
         "Principal" : { "AWS" : "arn:aws:iam::<main-account>:root" },
         "Condition":{
            "Bool":{
               "kms:GrantIsForAWSResource": true
            }
         }
      }
   ]
}
POLICY              
}

# AWS Backup vault
resource "aws_backup_vault" "backup-vault" {
   name        = "some-backup-vault-name"
   kms_key_arn = aws_kms_key.backup-key.arn
   tags = {
      Solution-ID= "my-test-backup"
   }
}

# Cross Account backup vault
resource "aws_backup_vault" "diff-account-vault" {
   provider    = aws.crossbackup
   name        = "some-cross-account-vault-name"
   kms_key_arn = aws_kms_key.dest-backup-key.arn
}

# AWS Backup plan
resource "aws_backup_plan" "backup-plan" {
   name = "some-backup-plan-name"
   rule {
      rule_name         = "some-backup-plan-rule-name"
      target_vault_name = aws_backup_vault.backup-vault.name
      schedule          = "cron(0 01-04 * * ? *)" 
      recovery_point_tags = {
         Solution-ID = "my-test-backup"
      }
      copy_action {
         destination_vault_arn = aws_backup_vault.diff-account-vault.arn
      }
   }
}

# AWS Backup selection with tags
resource "aws_backup_selection" "backup-selection" {
   name         = "some-backup-selection-name"
   iam_role_arn = aws_iam_role.aws-backup-service-role.arn
   plan_id      = aws_backup_plan.backup-plan.id
   selection_tag {
      type  = var.selection-type
      key   = "Solution-ID"
      value = "my-test-backup"
   }
}

resource "aws_backup_vault_policy" "organization-level-policy" {
   backup_vault_name = aws_backup_vault.backup-vault.name

   policy = <<POLICY
{
   "Version":"2012-10-17",
   "Statement":[
      {
         "Effect":"Allow",
         "Action":"backup:CopyIntoBackupVault",
         "Resource":"*",
         "Principal":"*",
         "Condition":{
            "StringEquals":{
               "aws:PrincipalOrgID":[
                  "<Organization-ID>"
               ]
            }
         }
      }
   ]
}
POLICY
}

# Cross Account backup policy, Organization level
resource "aws_backup_vault_policy" "organization-policy" {
   backup_vault_name = aws_backup_vault.diff-account-vault.name
   provider          = aws.crossbackup

   policy = <<POLICY
{
   "Version":"2012-10-17",
   "Statement":[
      {
         "Effect":"Allow",
         "Action":"backup:CopyIntoBackupVault",
        "Resource":"*",
         "Principal":"*",
         "Condition":{
            "StringEquals":{
               "aws:PrincipalOrgID":[
                   "<Organization-ID>"
               ]
            }
         }
      }
   ]
}
POLICY
}

variable "selection-type" {
   type        = string
   description = "Name for the Selection type"
   default     = "STRINGEQUALS"
}