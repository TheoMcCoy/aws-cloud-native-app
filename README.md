# Exercise 3 – AWS Cloud Native App (Terraform)

This project provisions a **cloud-native application** on AWS using Terraform only.  
It creates a secure VPC architecture spanning multiple availability zones, with public and private subnets, NAT gateway, Bastion host, Application Load Balancer, Auto Scaling Group of web servers, and a MongoDB database in the private subnet.

---

## 📷 Architecture

![Architecture Diagram](https://github.com/TheoMcCoy/aws-cloud-native-app/blob/main/docs/AWS-VPC-FullApp-TargetGrps.png)

---

## 🚀 What’s Included

- **VPC**
  - 2 Availability Zones
  - Public + private subnets
  - Internet Gateway + NAT Gateway
  - Separate public and private route tables

- **Compute**
  - Bastion host in public subnet (for SSH access into private subnet)
  - Auto Scaling Group (ASG) of Amazon Linux 2 EC2 instances
    - Bootstrapped with Nginx
    - Pulls frontend + API from GitHub repos
  - MongoDB EC2 instance in private subnet

- **Load Balancing**
  - Application Load Balancer (ALB)
  - 2 Target Groups:
    - Port 80 → frontend
    - Port 8080 → API

- **Security**
  - Security Groups for Bastion, ALB, Web, and MongoDB
  - Private instances only accessible via Bastion host

---

## 🔗 Application Components

- **Frontend** (React):  
  https://github.com/cloudacademy/voteapp-frontend-react-2020/releases/latest  

- **API** (Go):  
  https://github.com/cloudacademy/voteapp-api-go/releases/latest  

- **Database**: MongoDB running inside the private subnet  

---

## ⚡️ Deployment

```bash
# Clone the repo
git clone https://github.com/<your-username>/aws-cloud-native-app.git
cd aws-cloud-native-app

# Initialize Terraform
terraform init

# Review plan
terraform plan -var-file="terraform.tfvars"

# Apply
terraform apply -var-file="terraform.tfvars"

