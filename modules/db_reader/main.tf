locals {
 selected_subnet_ids = var.public_subnet ? data.aws_subnets.public.ids : data.aws_subnets.private.ids
}

resource "aws_iam_role" "db_reader_role" {
  name = "${var.name_prefix}-db-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "db_read_list_all" {
  name        = "${var.name_prefix}-dynamodb-policy"
  description = "Policy to allow EC2 to list and read from DynamoDB tables"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "VisualEditor0",
        Effect   = "Allow"
        Action   = [
            "dynamodb:BatchGetItem",
            "dynamodb:DescribeImport",
            "dynamodb:ConditionCheckItem",
            "dynamodb:DescribeContributorInsights",
            "dynamodb:Scan",
            "dynamodb:ListTagsOfResource",
            "dynamodb:Query",
            "dynamodb:DescribeStream",
            "dynamodb:DescribeTimeToLive",
            "dynamodb:DescribeGlobalTableSettings",
            "dynamodb:PartiQLSelect",
            "dynamodb:DescribeTable",
            "dynamodb:GetShardIterator",
            "dynamodb:DescribeGlobalTable",
            "dynamodb:GetItem",
            "dynamodb:DescribeContinuousBackups",
            "dynamodb:DescribeExport",
            "dynamodb:GetResourcePolicy",
            "dynamodb:DescribeKinesisStreamingDestination",
            "dynamodb:DescribeBackup",
            "dynamodb:GetRecords",
            "dynamodb:DescribeTableReplicaAutoScaling"
        ]
        Resource = "arn:aws:dynamodb:us-east-1:255945442255:table/${var.name_prefix}-bookinventory"
      },
      {
        Sid = "VisualEditor1",
        Effect = "Allow",
        Action = [
                "dynamodb:ListContributorInsights",
                "dynamodb:DescribeReservedCapacityOfferings",
                "dynamodb:ListGlobalTables",
                "dynamodb:ListTables",
                "dynamodb:DescribeReservedCapacity",
                "dynamodb:ListBackups",
                "dynamodb:GetAbacStatus",
                "dynamodb:ListImports",
                "dynamodb:DescribeLimits",
                "dynamodb:DescribeEndpoints",
                "dynamodb:ListExports",
                "dynamodb:ListStreams"
            ],
        Resource = "*"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "db_reader_attachment" {
  policy_arn = aws_iam_policy.db_read_list_all.arn
  role       = aws_iam_role.db_reader_role.name
}


resource "aws_iam_instance_profile" "db_reader" {
  name = "${var.name_prefix}-db_reader-profile"
  role = aws_iam_role.db_reader_role.name
}

resource "aws_instance" "db_reader" {
 count                  = var.instance_count
 ami                    = data.aws_ami.latest.id
 instance_type          = var.instance_type
 key_name               = var.key_name
 subnet_id              = local.selected_subnet_ids[count.index % length(local.selected_subnet_ids)]
 vpc_security_group_ids = [aws_security_group.db_reader.id]
 iam_instance_profile   = aws_iam_instance_profile.db_reader.name
 user_data              = templatefile("${path.module}/init-script.sh", {
   file_content = "dbreader-#${count.index}"})


 associate_public_ip_address = true
 tags = {
   Name = "${var.name_prefix}-dbreader-${count.index}"
 }
}


resource "aws_security_group" "db_reader" {
 name_prefix = "${var.name_prefix}-dbreader"
 description = "Allow traffic to dbreader"
 vpc_id      = data.aws_vpc.selected.id


# Allow HTTP traffic from anywhere

  ingress {
   from_port        = 443
   to_port          = 443
   protocol         = "tcp"
   cidr_blocks      = ["0.0.0.0/0"]
   ipv6_cidr_blocks = ["::/0"]
 }

 # Allow SSH access only from anywhere
 ingress {
   from_port        = 22
   to_port          = 22
   protocol         = "tcp"
   cidr_blocks      = ["0.0.0.0/0"]
   ipv6_cidr_blocks = ["::/0"]
 }


 egress {
   from_port        = 0
   to_port          = 0
   protocol         = "-1"
   cidr_blocks      = ["0.0.0.0/0"]
   ipv6_cidr_blocks = ["::/0"]
 }


 lifecycle {
   create_before_destroy = true
 }
}


output "public_ip" {
 value = aws_instance.db_reader[*].public_ip
}