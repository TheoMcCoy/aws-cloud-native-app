# AWS Cloud Native App with Terraform

This repository provisions a **cloud-native web application stack** on AWS using Terraform with user_data bootstrapping (no Ansible).  
It includes network setup (VPC, subnets, NAT), bastion, ALB, ASG, frontend + API, and MongoDB.

---

## 📷 Architecture

![Architecture Diagram](https://github.com/TheoMcCoy/aws-cloud-native-app/blob/main/docs/AWS-VPC-FullApp-TargetGrps.png)

---

## 🚀 What It Does

- Creates a **VPC** across 2 AZs with public + private subnets  
- Deploys **Internet Gateway + NAT Gateway**  
- Launches a **Bastion host** (public subnet)  
- Deploys **Auto Scaling Group (ASG)** of Amazon Linux 2 EC2s  
  - Bootstraps frontend (React) + API (Go) from GitHub releases  
- Deploys a **MongoDB EC2** in the private subnet  
- Configures an **Application Load Balancer (ALB)** targeting both frontend (port 80) and API (port 8080)  
- Applies **security groups** to isolate components securely

---

## 🛠 Prerequisites

- Terraform v1.x  
- AWS CLI configured (`aws configure`)  
- SSH keypair created in AWS  
- Git installed locally

---

## 📂 File Structure
```bash
├── main.tf
├── variables.tf
├── terraform.tfvars
├── outputs.tf
├── docs/
│ └── architecture.png
└── .gitignore
```
---

## ⚙️ Getting Started

```bash
# Clone the repo
git clone https://github.com/<your-username>/exercise-3-cloud-native-app.git
cd exercise-3-cloud-native-app

# (Optional) Place architecture.png under docs/

terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"

# After apply:
terraform output alb_dns_name
```
Open http://<alb_dns_name> in your browser.

## 🔐 Access & Debugging

1. SSH to bastion:
```bash
ssh -i <your-key.pem> ec2-user@<bastion_public_ip>
```

2. From bastion, SSH into private instance:
```bash
ssh ec2-user@<private_instance_ip>
```

3. Inspect logs:
```bash
sudo tail -f /var/log/userdata.log
sudo systemctl status nginx
```
## 🧹 Teardown

To clean up resources:
```bash
terraform destroy -var-file="terraform.tfvars"
```



