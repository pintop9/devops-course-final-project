<h1 align=center>Candies and Snacks E-Commerce Website with Django + React & Redux</h1>

## ✨ About the project

This is a full-stack e-commerce web application built with Django, React, and Redux. It provides a comprehensive set of features for both customers and administrators to buy and sell candies and snacks.

### How to Run 🏃‍♀️

This application relies on a PostgreSQL database. For local development, it is recommended to use Docker to run the application, as direct local execution of the Django backend without a containerized database is not supported.

#### With Docker

```shell
# Clone this repository
git clone https://github.com/pintop9/devops-course-final-project.git

# Navigate to the project directory
cd devops-course-final-project


# Run the containers and build the images in one command
docker-compose up
```

### 🛠️ Technologies Used

*   **Backend:** Django, Django REST Framework
*   **Frontend:** React, Redux
*   **Database:** PostgreSQL
*   **Containerization:** Docker
*   **Cloud Provider:** AWS
*   **Infrastructure as Code:** Terraform
*   **CI/CD:** Jenkins

### Deploy to AWS with Terraform 🚀

This project can be deployed to AWS Cloud using Terraform. This will provision a Jenkins master and a Jenkins agent instance. The Jenkins master will be **pre-configured using Jenkins Configuration as Code (CasC)**, defining plugins, credentials (placeholders), and the main pipeline job from the repository. This automates much of the initial Jenkins setup.

#### Prerequisites

*   **AWS Account:** Ensure you have an active AWS account.
*   **AWS CLI Configured:** Configure your AWS CLI with appropriate credentials and a default region.
*   **Terraform:** Install Terraform on your local machine.
*   **SSH Key:** Ensure you have an SSH key named `aws_tf` in the region specified in `main.tf` (il-central-1). You can create one via the AWS EC2 console if you don't have one.

#### Important Note on Jenkins URL Configuration:

The `jenkins.yaml` configuration includes a placeholder for `unclassified.location.url` (e.g., `http://localhost:8080`). Since the Jenkins master's IP address is dynamically provisioned by Terraform, you will need to **manually update this Jenkins URL** after deployment via `Manage Jenkins` -> `Configure System` -> `Jenkins Location`. This ensures Jenkins generates correct links for notifications and other features.

#### Deployment Steps

1.  **Initialize Terraform:**
    Navigate to the root of the project where `main.tf` is located and initialize Terraform.
    ```bash
    terraform init
    ```

2.  **Review the Plan (Optional but Recommended):**
    See what Terraform will provision before actually creating resources.
    ```bash
    terraform plan
    ```

3.  **Apply the Configuration:**
    Execute the Terraform configuration to provision the AWS resources.
    ```bash
    terraform apply --auto-approve
    ```
    This will output the public IP addresses of the Jenkins master and agent. Make a note of them.

#### Post-Deployment Configuration

After Terraform successfully provisions the instances, you need to perform a few manual steps to connect the Jenkins master and agent:

1.  **Retrieve Jenkins Master's Public SSH Key:**
    SSH into the Jenkins master instance (using the `aws_tf` key and its public IP) and retrieve the public key for the `jenkins` user:
    ```bash
    sudo cat /var/lib/jenkins/.ssh/id_rsa.pub
    ```
    Copy the entire output (it starts with `ssh-rsa ...`).

2.  **Add Master's Public Key to Agent:**
    
    The `aws_tf` key is for *your* SSH access to *both* instances. The `jenkins` user's key (generated on the master) is for the *Jenkins master* to access the *Jenkins agent*.

    SSH into the Ubuntu agent instance (using the `aws_tf` key and its public IP). Then, as a user with `sudo` privileges, execute the following commands.
    ```bash
    echo "<JENKINS_MASTER_PUBLIC_KEY>" | sudo tee -a /home/jenkins/.ssh/authorized_keys
    sudo chown jenkins:jenkins /home/jenkins/.ssh/authorized_keys
    sudo chmod 600 /home/jenkins/.ssh/authorized_keys
    ```
    Replace `<JENKINS_MASTER_PUBLIC_KEY>` with the actual public key you copied from the master.

3.  **Access Jenkins UI and Configure Agent:**
    *   Open your web browser and navigate to `http://<JENKINS_MASTER_PUBLIC_IP>:8080` (replace `<JENKINS_MASTER_PUBLIC_IP>` with the actual IP).
    *   Follow the Jenkins setup wizard. You will need to get the initial admin password from the master instance's logs.
    *   Once Jenkins is set up, go to "Manage Jenkins" -> "Nodes" -> "New Node".
    *   Create a new permanent agent.
    *   Configure the node with the following:
        *   **Host:** The public IP of your Ubuntu agent instance.
        *   **Credentials:** Add new SSH credentials.
            *   **Scope:** System
            *   **ID:** (choose a unique ID, e.g., `jenkins-agent-ssh-key`)
            *   **Description:** (e.g., `SSH key for Jenkins agent`)
            *   **Username:** `jenkins`
            *   **From the Jenkins master, get the private key by running:**
                ```bash
                sudo cat /var/lib/jenkins/.ssh/id_rsa
                ```
                Paste the entire content of the private key into the "Private Key" field in Jenkins.
        *   **Host Key Verification Strategy:** Select "Non verifying Verification Strategy" (for simplicity in a development environment, but not recommended for production).
        *   **Launch method:** Launch agent via SSH.
        *   **Remote root directory:** `/home/jenkins`
    *   Save the configuration. Jenkins master should now connect to the agent.

#### Security Warning for CasC Configuration

**IMPORTANT:** The `casc_configs/jenkins.yaml` file, especially when containing sensitive information like Docker Hub credentials (e.g., `YOUR_DOCKERHUB_USERNAME`, `YOUR_DOCKERHUB_PASSWORD`) or plaintext admin passwords, should **NEVER be committed directly to a public version control system (like Git) in plaintext.**

While CasC allows you to define credentials in YAML, for production environments, it is highly recommended to:
*   **Use Jenkins' encrypted secrets:** For passwords directly in `jenkins.yaml`, utilize encrypted password hashes generated by Jenkins (as shown for the `admin` user password).
*   **Integrate with external secret management systems:** For highly sensitive credentials (like Docker Hub tokens), consider using solutions like HashiCorp Vault, AWS Secrets Manager, or Kubernetes Secrets to manage and inject them securely into Jenkins at runtime.

Always ensure sensitive data is handled with appropriate security measures.

### 🚀 Deployment Types

This project supports the following deployment strategies:

*   **Local Development (Dockerized):** For local development and testing, the application can be run using Docker Compose, which sets up the Django backend, React frontend, and PostgreSQL database in isolated containers.
*   **AWS Cloud (CI/CD):** The application can be deployed to AWS using Terraform for infrastructure provisioning and Jenkins for continuous integration and continuous delivery. This setup automates the build, test, and deployment processes.

### 📷 Project Screenshots

![ss](./ss/ss1.png)
![ss](./ss/ss2.png)
![ss](./ss/ss3.png)
![ss](./ss/ss4.png)
![ss](./ss/ss5.png)
![ss](./ss/ss6.png)

### 🚀 Project Features

A completely customized eCommerce / shopping cart application using Django, REACT and REDUX with the following functionality:

- Full featured shopping cart
- Product reviews and Ratings
- Top products carousel
- Product pagination
- Product search feature
- User profile with orders
- Admin product management
- Admin user management
- Admin Order details page
- Mark orders as a delivered option
- Checkout process (shipping, payment method, etc)
- PayPal / credit card integration
