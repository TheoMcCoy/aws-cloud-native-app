terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">=6.14.1"
    }
  }
}

provider "aws" {
 region = var.region
}

data "aws_availability_zones" "azs" {
    state = "available"  
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    Name = "${var.name_prefix}-vpc"
  }
}

resource "aws_subnet" "public" {
  for_each = {for idx, cidr in var.public_subnet_cidr : idx => cidr}

  vpc_id = aws_vpc.main.id
  cidr_block = each.value
  availability_zone = data.aws_availability_zones.azs.names[each.key]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name_prefix}-public-${each.key}"
  }
}

resource "aws_subnet" "private" {
    for_each = {for idx, cidr in var.private_subnet_cidr : idx => cidr}

    vpc_id = aws_vpc.main.id
    cidr_block = each.value
    availability_zone = data.aws_availability_zones.azs.names[each.key]

    tags = {
    Name = "${var.name_prefix}-private-${each.key}"
  }
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.name_prefix}-igw"
    }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_assoc" {
  for_each = aws_subnet.public
  subnet_id = each.value.id
  route_table_id = aws_route_table.public.id
}

# NAT Gateway (single NAT for demo)
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "${var.name_prefix}-nat-eip"
  }
}

resource "aws_nat_gateway" "nat" {
    allocation_id = aws_eip.nat_eip.id
  subnet_id = aws_subnet.public[0].id

  tags = {
    Name = "${var.name_prefix}-natgw"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name_prefix}-private-rt"
  }
}

resource "aws_route" "private_nat_gateway" {
  route_table_id = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private_a" {
  subnet_id = aws_subnet.private[0].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
    subnet_id = aws_subnet.private[1].id
    route_table_id = aws_route_table.private.id  
}

# Security Groups
resource "aws_security_group" "alb_sg" {
  name = "${var.name_prefix}-alb-sg"
  description = "ALB security group - allow HTTP from internet"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "HTTP from internet"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { 
    Name = "${var.name_prefix}-alb-sg" 
  }
}

resource "aws_security_group" "instance-sg" {
  name = "${var.name_prefix}-instance-sg"
  description = "ASG instance SG - allow ports 80 & 8080 from ALB"
  vpc_id = aws_vpc.main.id

#   HTTP from ALB
ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
    description = "ALB -- frontend (nginx)"
}

# API port from ALB
ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
    description = "ALB -- api"
}

ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH (admin)"
}
egress {
    to_port = 0
    from_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
}
tags = { Name = "${var.name_prefix}-instance-sg" }
}

resource "aws_security_group" "mongodb_sg" {
  name = "${var.name_prefix}-mongodb-sg"
  description = "MongoDB SG - only allow ASG instanceto talk to DB"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 27017
    to_port = 27017
    protocol = "tcp"
    security_groups = [aws_security_group.instance-sg.id]
    description = "ASG -- MongoDB"
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name_prefix}-mongodb-sg" }
}

#Bastion host security group
resource "aws_security_group" "bastion_sg" {
  name = "${var.name_prefix}-bastion-sg"
  description = "Allow SSH"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
}

# IAM role & profile for SSM (so private instances can be accessed using Session Manager)
data "aws_iam_policy_document" "assume_ec2" {
  statement {
    actions = ["sts:AssumeRole"]
    principals { 
        type = "Service"
         identifiers = ["ec2.amazonaws.com"] 
         }
  }
}

resource "aws_iam_role" "instance_role" { 
    name = "${var.name_prefix}-role"
    assume_role_policy = data.aws_iam_policy_document.assume_ec2.json 
    }

resource "aws_iam_role_policy_attachment" "ssm_attach" { 
    role = aws_iam_role.instance_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore" 
    }

resource "aws_iam_instance_profile" "instance_profile" { 
    name = "${var.name_prefix}-inst-profile"
    role = aws_iam_role.instance_role.name 
    }

# Application load balancer
resource "aws_lb" "alb" {
  name = "${var.name_prefix}-alb"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.alb_sg.id]
  subnets = [for subnet in aws_subnet.public : subnet.id]
}

resource "aws_lb_target_group" "frontend" {
  name = "${var.name_prefix}-frontend-tg"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.main.id
}

resource "aws_lb_target_group" "api" {
  name = "${var.name_prefix}-api-tg"
  port = 8080
  protocol = "HTTP"
  vpc_id = aws_vpc.main.id
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

# Lauch template and ASG
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners = [ "amazon" ]

  filter {
    name = "name"
    values = [ "amzn2-ami-hvm-*-x86_64-gp2" ]
  }
}

# Bastion Instance
resource "aws_instance" "bastion" {
    ami = data.aws_ami.amazon_linux_2.id
    instance_type = var.instance_type
    subnet_id = aws_subnet.public[0].id
    key_name = var.key_name
    vpc_security_group_ids = [aws_security_group.bastion_sg.id]  
    associate_public_ip_address = true
}

resource "aws_launch_template" "web_lt" {
    name_prefix = "${var.name_prefix}-lt"
    image_id = data.aws_ami.amazon_linux_2.id
    instance_type = var.instance_type
    vpc_security_group_ids = [ aws_security_group.instance-sg.id ]
    key_name = var.key_name

    iam_instance_profile {
      name = aws_iam_instance_profile.instance_profile.name
    }
user_data = base64encode(<<-EOF
  #!/bin/bash -xe

echo "=== Starting user_data script at $(date) ===" >> /var/log/userdata.log

# Wait for networking
sleep 15

# Install nginx, git, jq
yum -y update
amazon-linux-extras enable nginx1
yum clean metadata
yum install -y nginx jq git

systemctl enable nginx
systemctl start nginx

ALB_DNS=${aws_lb.alb.dns_name}
MONGODB_PRIVATEIP=${aws_instance.mongodb.private_ip}

mkdir -p /tmp/cloudacademy-app
cd /tmp/cloudacademy-app

echo "=== FRONTEND INSTALL ===" >> /var/log/userdata.log
mkdir -p ./frontend && cd ./frontend

# Download latest frontend release dynamically
FRONTEND_URL=$(curl -sL https://api.github.com/repos/cloudacademy/voteapp-frontend-react-2020/releases/latest \
  | jq -r '.assets[0].browser_download_url')
FRONTEND_FILE=$(curl -sL https://api.github.com/repos/cloudacademy/voteapp-frontend-react-2020/releases/latest \
  | jq -r '.assets[0].name')

echo "Downloading frontend: $FRONTEND_FILE from $FRONTEND_URL" >> /var/log/userdata.log
curl -L -o "$FRONTEND_FILE" "$FRONTEND_URL"

# Extract using the correct filename
tar -xvzf "$FRONTEND_FILE"

# Verify that build folder exists
if [ -d "build" ]; then
  echo "Frontend build directory exists. Copying to nginx..." >> /var/log/userdata.log
  rm -rf /usr/share/nginx/html
  cp -R build /usr/share/nginx/html

  # Inject environment variable for React app
  cat > /usr/share/nginx/html/env-config.js << EOFF
window._env_ = {REACT_APP_APIHOSTPORT: "$ALB_DNS"}
EOFF
else
  echo "ERROR: Frontend build directory NOT found! Check archive structure." >> /var/log/userdata.log
fi

cd ..

echo "=== API INSTALL ===" >> /var/log/userdata.log
mkdir -p ./api && cd ./api

# Download latest API release dynamically
API_URL=$(curl -sL https://api.github.com/repos/cloudacademy/voteapp-api-go/releases/latest \
  | jq -r '.assets[] | select(.name | contains("linux-amd64")) | .browser_download_url')
API_FILE=$(curl -sL https://api.github.com/repos/cloudacademy/voteapp-api-go/releases/latest \
  | jq -r '.assets[] | select(.name | contains("linux-amd64")) | .name')

echo "Downloading API: $API_FILE from $API_URL" >> /var/log/userdata.log
curl -L -o "$API_FILE" "$API_URL"

# Extract API
tar -xvzf "$API_FILE"

# Verify API binary exists before starting
if [ -f "./api" ]; then
  echo "API binary exists. Starting API..." >> /var/log/userdata.log
  nohup ./api --mongo "mongodb://$MONGODB_PRIVATEIP:27017/langdb" &
else
  echo "ERROR: API binary NOT found! Check archive structure." >> /var/log/userdata.log
fi

systemctl restart nginx
echo "=== Finished user_data script at $(date) ===" >> /var/log/userdata.log

EOF
)


}

resource "aws_autoscaling_group" "web_asg" {
#   name = "${var.name_prefix}-asg"         //If you using default VPC you can uncomment this line
  min_size = var.asg_min_size
  max_size = var.asg_max_size
  desired_capacity = var.asg_desired_capacity
  vpc_zone_identifier = [for s in aws_subnet.private : s.id]
  launch_template {
    id = aws_launch_template.web_lt.id
    version = "$Latest"
  }
  target_group_arns = [aws_lb_target_group.frontend.arn, aws_lb_target_group.api.arn]
  health_check_type = "EC2"
  
  tag {
    key = "Name"
    value = "${var.name_prefix}-web-asg"
    propagate_at_launch = true
  }
    lifecycle {
    create_before_destroy = true
    }
}

# MongoDB instance
resource "aws_instance" "mongodb" {
    ami = data.aws_ami.amazon_linux_2.id
    instance_type = var.instance_type
    subnet_id = aws_subnet.private[0].id
    security_groups = [ aws_security_group.mongodb_sg.id ]
    
    user_data = <<-EOF
    #!/bin/bash
    yum -y update
    amazon-linux-extras enable corretto8
    yum install -y mongodb-org
    systemctl enable mongod
    systemctl start mongod
  EOF
  
  tags = { Name = "${var.name_prefix}-mongodb" }
}

