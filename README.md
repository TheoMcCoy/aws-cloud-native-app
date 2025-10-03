# Exercise 3 – AWS Cloud Native App with Terraform

This repository provisions a **cloud-native web application stack** on AWS using Terraform with user_data bootstrapping (no Ansible).  
It includes network setup (VPC, subnets, NAT), bastion, ALB, ASG, frontend + API, and MongoDB.

---

## 📷 Architecture

![Architecture Diagram] https://github.com/TheoMcCoy/aws-cloud-native-app/blob/main/docs/AWS-VPC-FullApp-TargetGrps.png 

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
