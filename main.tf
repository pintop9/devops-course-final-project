terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
provider "aws" {
  region                   = "il-central-1"
  shared_config_files      = ["~/.aws/config"]
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "default"
}
resource "aws_ebs_volume" "jenkins_volume" {
  availability_zone = "il-central-1b"
  size              = 8
}
data "aws_vpc" "default" {
  default = true
}


data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_security_group" "jenkins_master_sg" {
  name_prefix = "jenkins-master-sg-"
  description = "Security group for Jenkins Master"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow SSH from anywhere
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow Jenkins UI from anywhere
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins_master_sg"
  }
}

resource "aws_security_group" "jenkins_agent_sg" {
  name_prefix = "jenkins-agent-sg-"
  description = "Security group for Jenkins Agent"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.jenkins_master_sg.id] # Allow SSH from Jenkins Master
  }
  
  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins_agent_sg"
  }
}



resource "aws_instance" "jenkins" {
  ami             = "ami-07c0a4909b86650c0"
  instance_type   = "t3.micro"
  subnet_id       = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.jenkins_master_sg.id]
  availability_zone = "il-central-1b"
  key_name      = "aws_tf"

  root_block_device {
    volume_size           = 30
    delete_on_termination = true 
  }

  tags = {
    Name = "jenkins_master"
  }
 
  user_data = <<-EOF
    #!/bin/bash

    sudo apt update
    sudo apt install -y git fontconfig openjdk-21-jre docker.io 

    echo "Java, Git, and Python installed"

    sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
      https://pkg.jenkins.io/debian/jenkins.io-2023.key
    echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian binary/" \
      | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

    sudo apt update
    sudo apt install -y jenkins
    sudo usermod -aG docker jenkins
    sudo service jenkins restart

    echo "Jenkins installed successfully..."

    # Clone the project repository for CasC configuration
    sudo git clone https://github.com/pintop9/devops-course-final-project.git /var/lib/jenkins/devops-course-final-project
    sudo chown -R jenkins:jenkins /var/lib/jenkins/devops-course-final-project

    # Create directory for CasC config and copy files
    sudo mkdir -p /var/lib/jenkins/casc_configs
    sudo cp /var/lib/jenkins/devops-course-final-project/casc_configs/jenkins.yaml /var/lib/jenkins/casc_configs/
    sudo cp /var/lib/jenkins/devops-course-final-project/casc_configs/ecommerce-pipeline.yaml /var/lib/jenkins/casc_configs/
    sudo chown -R jenkins:jenkins /var/lib/jenkins/casc_configs

    # Configure Jenkins to use CasC by modifying the systemd service file
    sudo sed -i 's|ExecStart=.*|ExecStart=/usr/bin/java -Djava.awt.headless=true -jar /usr/share/jenkins/jenkins.war --webroot=/var/cache/jenkins/war --httpPort=8080 --CascConfig=/var/lib/jenkins/casc_configs/jenkins.yaml --daemon|' /lib/systemd/system/jenkins.service

    # Reload systemd and restart Jenkins to apply CasC
    sudo systemctl daemon-reload
    sudo service jenkins restart

    echo "Jenkins configured with CasC."

  EOF
}

resource "aws_volume_attachment" "jenkins_va" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.jenkins_volume.id
  instance_id = aws_instance.jenkins.id
}

resource "aws_instance" "jenkins_agent" {
  ami             = "ami-07c0a4909b86650c0"
  instance_type   = "t3.micro"
  subnet_id       = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.jenkins_agent_sg.id]
  availability_zone = "il-central-1b"
  key_name      = "aws_tf"

  root_block_device {
    volume_size           = 8
    delete_on_termination = true 
  }

  tags = {
    Name = "jenkins_agent"
  }
   user_data = <<-EOF
    #!/bin/bash

    sudo apt update
    sudo apt install -y fontconfig openjdk-21-jre docker.io python3.11-venv git

    echo "Java, Docker, Python and Git installed"

    # Install Docker Compose
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose

    echo "Docker Compose installed"

    # Create jenkins user if it doesn't exist
    sudo id -u jenkins &>/dev/null || sudo useradd -m -s /bin/bash jenkins

    # Allow jenkins user to run docker commands
    sudo usermod -aG docker jenkins

    # Create .ssh directory and authorized_keys file for jenkins user
    sudo -u jenkins mkdir -p /home/jenkins/.ssh
    sudo -u jenkins touch /home/jenkins/.ssh/authorized_keys
    sudo -u jenkins chmod 700 /home/jenkins/.ssh
    sudo -u jenkins chmod 600 /home/jenkins/.ssh/authorized_keys
    sudo chown -R jenkins:jenkins /home/jenkins/.ssh

    echo "Jenkins agent setup complete. Waiting for Jenkins master to connect..."
  EOF
}
resource "aws_ebs_volume" "jenkins_agent_volume" {
  availability_zone = "il-central-1b"
  size              = 8
}
resource "aws_volume_attachment" "jenkins_agent_va" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.jenkins_agent_volume.id
  instance_id = aws_instance.jenkins_agent.id
}




output "jenkins_master_public_ip" {
  description = "The public IP address of the Jenkins master instance"
  value       = aws_instance.jenkins.public_ip
}

output "jenkins_agent_public_ip" {
  description = "The public IP address of the Jenkins agent instance"
  value       = aws_instance.jenkins_agent.public_ip
}