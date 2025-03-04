# ARCHITECTURE.md

## Introduction
This document describes the architecture and deployment process for the vertica database. The solution provisions a **Vertica** analytical database on **AWS EKS** using **Terraform** for infrastructure as code and a custom **Helm chart** for Kubernetes deployment.

## Tech Stack
### Cloud Provider and Kubernetes
- **Cloud Provider:** AWS (Amazon Web Services)
- **Kubernetes:** Amazon Elastic Kubernetes Service (**EKS**)
- **Infrastructure as Code:** Terraform with modular design
- **Helm Chart:** Custom Helm chart to deploy Vertica


## Infrastructure Overview
The infrastructure is defined using Terraform with separate modules for different components:

```
main.tf
provider.tf
variables.tf
output.tf
modules/
  eks/
  aws_lb_balancer/
  metrics_server/
  vertica_operator/
  vpc/
  database/
```

## Thought Process & Decision Making
### **Cloud Provider Choice: AWS**
- AWS was selected due to its robust managed services, specifically **EKS**, which simplifies Kubernetes management.
- AWS provides **IAM Roles for Service Accounts (IRSA)**, which enhances security by giving fine-grained permissions to Kubernetes workloads instead of using access key ID and secret access key.

### **Kubernetes Cluster: EKS**
- A managed Kubernetes cluster was chosen to reduce operational overhead.
- It supports auto-scaling, easy integration with AWS services, and provides **OIDC authentication** for secure access control.

### **Infrastructure as Code: Terraform**
- Terraform ensures infrastructure is **declarative, repeatable, and version-controlled**.
- Modules were created for **VPC, EKS, Load Balancer, Metrics Server, Vertica Operator, and Database** to **promote modularity and reusability**.
- **IRSA integration** allows Vertica to securely communicate with AWS services (e.g., S3).

### **Helm Chart for Vertica**
- Helm was used to **simplify deployments, manage configurations, and support versioning**.
- in this **custom Helm chart** we deployed following resources:
  - **VerticaDB CRD** is used to deploy database nodes.
  - **EventTrigger CRD** is used to deploy a job to configure internode encryption for the data channel by self-signed certificate


### **Internode Security (Control Channel & Data Channel)**
- Vertica uses two separate communication channels between nodes:
  1. **Control Channel (Spread Communication)**: Automatically secured using **EncryptSpreadComm**, enabled by default in the `VerticaDB` CRD.
  2. **Data Channel**: Requires explicit configuration to enable TLS encryption.

- **How Data Channel TLS was Implemented:**
  - A **EventTrigger CRD** is included in the Helm chart to automate the configuration of **Data Channel TLS**.
  - This will create a kubernetes job:
    - This job Waits until the Vertica database is ready.
    - Checks if internode encryption is already configured.
    - If not, it:
      - Creates a **self-signed certificate authority (CA)**.
      - Generates a **TLS certificate** for internode communication.
      - Configures the **Vertica database to use TLS** for its data channel.

- **Why This Approach Was Used:**
  - The official [Vertica Internode TLS Documentation](https://docs.vertica.com/25.1.x/en/security-and-authentication/internode-tls/data-channel-tls/) requires manual SQL commands.
  - Automating with a **EventTrigger CRD** ensures consistency and eliminates manual intervention.
  - By **Self-signed certificates**, an certificate is created easily and used by vertica which is enough for this task.

### **Affinity Rules for Vertica Nodes**
- **Why Affinity Rules Were Used:**
  - According to the [Vertica documentation](https://docs.vertica.com/25.1.x/en/containerized/custom-resource-definitions/), **each Vertica node must operate in the same availability zone** in cloud or managed Kubernetes environments.
  - To enforce this constraint, we applied **pod affinity rules** in the `vdb.yaml` Helm configuration:

    ```yaml
    affinity:
      podAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
                - key: app.kubernetes.io/name
                  operator: In
                  values:
                    - vertica
            topologyKey: topology.kubernetes.io/zone
    ```
  - This ensures that all Vertica pods are scheduled **within the same availability zone**, preventing cross-AZ communication overhead and improving **performance and stability**.

### **Why VerticaAutoscaler CRD Was Not Used**
- Vertica’s **VerticaAutoscaler** CRD supports automatic scaling, but was not implemented due to:
  1. **Vertica recommends minimum 3 nodes** for stability.
  2. **Challenge requirement**: exactly 3 nodes.
  3. **Community Edition** license restricts to 3 nodes & 1TB max. Autoscaling beyond 3 is unsupported.


## Terraform Configuration
Terraform uses input variables to configure the deployment, and outputs to provide information about deployed resources.

### Terraform Variables (`variables.tf`)
| Variable Name                 | Description                                                      | Type             | Default       |
|-------------------------------|------------------------------------------------------------------|------------------|---------------|
| `aws_region`                  | The AWS region                                                  | `string`         | `us-east-1`   |
| `aws_profile`                 | The AWS profile                                                 | `string`         | `default`     |
| `vpc_name`                    | VPC name                                                        | `string`         | -             |
| `vpc_cidr`                    | The CIDR block for the VPC                                      | `string`         | -             |
| `eks_cluster_name`            | The EKS cluster name                                            | `string`         | -             |
| `eks_version`                 | The Kubernetes version for the EKS cluster                      | `string`         | `1.32`        |
| `eks_node_count`              | The number of nodes in the K8s cluster                          | `map(string)`    | `{ min=3, desired=3, max=3 }` |
| `eks_disk_size`               | The size of the disk (in GB) for EKS nodes                      | `number`         | `100`         |
| `eks_instance_types`          | A list of EC2 instance types for the EKS nodes                  | `list(string)`   | -             |
| `resource_tags`               | A map of tags to assign to the resources                        | `map(string)`    | -             |
| `database_super_pass`         | The superuser password for the database                         | `string (sensitive)` | -       |
| `database_namespace`          | The Kubernetes namespace where the database resources will be deployed | `string` | `database`     |
| `database_bucket_name`        | The S3 bucket name which is used by Vertica                     | `string`         | -             |
| `enable_database_installation`| Enable database installation via Helm chart in Terraform        | `bool`           | `false`       |
| `database_super_username`     | The name of the database superuser                              | `string`         | `dbadmin`     |


> **Tip:** For **sensitive variables** such as `database_super_pass`, it’s best practice to set them as environment variables rather than storing them in plain text. For example:
>
> ```bash
> export TF_VAR_database_super_pass="mySuperSecretPassword"
> ```
>
> This helps keep secrets out of version control and logs.

### Terraform Outputs (`output.tf`)
| Output Name                          | Description                                  |
|--------------------------------------|----------------------------------------------|
| `vpc_id`                            | The VPC ID                                  |
| `vpc_cidr_block`                     | The VPC CIDR block                          |
| `vpc_igw_id`                         | The Internet Gateway ID                     |
| `vpc_main_route_table_id`            | The main route table ID                     |
| `vpc_private_subnets`                | List of private subnet IDs                  |
| `vpc_private_subnet_arns`            | List of private subnet ARNs                 |
| `vpc_private_subnets_cidr_blocks`    | List of private subnet CIDR blocks          |
| `vpc_private_route_table_ids`        | List of private route table IDs             |
| `vpc_public_subnets`                 | List of public subnet IDs                   |
| `vpc_public_subnet_arns`             | List of public subnet ARNs                  |
| `vpc_public_subnets_cidr_blocks`     | List of public subnet CIDR blocks           |
| `vpc_public_route_table_ids`         | List of public route table IDs              |
| `eks_cluster_identity_oidc_issuer`   | The OIDC issuer URL for the EKS cluster     |
| `eks_cluster_endpoint`               | The API server endpoint for the EKS cluster |
| `cluster_name`                       | The name of the EKS cluster                 |

## Security Considerations
- **IAM Roles for Service Accounts (IRSA)** used for secure AWS access.
- **Private and public subnets** configured for security.
- **Least privilege IAM policies** for Kubernetes workloads.
- **Proper tagging** for resources for security, compliance and cost optimization.

## Deployment Guide

### Prerequisites
Before proceeding with the deployment, ensure that the required tools are installed:

- **kubectl**: Kubernetes command-line tool ([Installation Guide](https://kubernetes.io/docs/tasks/tools/))
- **Helm**: Kubernetes package manager ([Installation Guide](https://helm.sh/docs/intro/install/))
- **Terraform**: Infrastructure as Code tool ([Installation Guide](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli))


Before running Terraform, ensure your AWS credentials are properly configured:

```bash
aws configure
```

### Terraform Deployment

Before deploying the main Terraform configuration, you need to set up an S3 bucket for the Terraform backend:

```bash
cd /terraform/backend
terraform init
terraform plan -out=tf.plan
terraform apply tf.plan
```

This will create an S3 bucket to be used as a backend for storing Terraform state files.

Then run terraform command to provision your infrastructure.

```bash
cd ../database
terraform init
terraform plan -var-file=dev.tfvars --output=tf.plan
terraform apply tf.plan
```

### Deploying Helm Chart
Before deploying the Helm chart, ensure your Kubernetes configuration is set to communicate with the EKS cluster:
```bash
aws eks update-kubeconfig --name [cluster-name] --region us-east-1 --profile [your-profile] --alias [cluster-name]
```
Then use helm command to install the application with proper values.

```bash
helm install vertica ./charts/database -f values.yaml --namespace vertica
```

There is an option to install the database via Terraform by adding `enable_database_installation` to your variable file and enabling it.

### Verifying Deployment
```bash
kubectl get pods -n vertica
kubectl get services -n vertica
```

## Helm Chart Configuration (`values.yaml`)
| Parameter                 | Description                                            | Default Value                 |
|---------------------------|--------------------------------------------------------|-------------------------------|
| `image.repository`        | Docker repository for Vertica                         | `opentext/vertica-k8s`        |
| `image.pullPolicy`        | Image pull policy                                    | `IfNotPresent`                |
| `image.tag`               | Image tag                                            | `""`                         |
| `local.storageClass`      | Storage class for persistent volume                   | `gp2`                         |
| `local.requestSize`       | Requested storage size                               | `500Gi`                       |
| `passwordSecret`          | Secret reference for database password               | `""`                          |
| `serviceAccountName`      | Service account name                                 | `""`                          |
| `annotations`             | Additional annotations for resources                 | `{}`                          |
| `communal.path`           | Path for communal storage                           | `""`                          |
| `communal.endpoint`       | Endpoint for communal storage                       | `""`                          |
| `communal.s3ServerSideEncryption` | S3 server-side encryption settings             | `""`                          |
| `communal.region`         | Region for communal storage                         | `""`                          |
| `subclusters.name`        | Name of the subcluster                               | `primary`                     |
| `subclusters.size`        | Number of nodes in the subcluster                    | `3`                           |
| `subclusters.serviceType` | Kubernetes service type (LoadBalancer)               | `LoadBalancer`                |
| `subclusters.loadBalancerScheme` | Load balancer scheme                           | `internet-facing`             |
| `dbName`                  | Name of the Vertica database                         | `vertdb`                      |
| `superUsername`           | The name of the database superuser                   | `dbadmin`                     |
| `imagePullSecrets`        | Image pull secrets                                  | `[]`                          |
| `nameOverride`            | Override name                                       | `""`                          |
| `fullnameOverride`        | Override full name                                  | `""`                          |
| `dataChannelEncryption`   | Enable data channel encryption                      | `true`                        |

## Additional Configuration Options

- To expose your service outside the Kubernetes cluster, set the `subclusters.serviceType` value in the Helm chart `values.yaml` to `LoadBalancer`. This will create a load balancer with an external IP.
- To encrypt the data channel between nodes, set the `dataChannelEncryption` value in your Helm `values.yaml` to `true`.


## Future Enhancements for Production Readiness

### Observability & Monitoring
- Integrate **Prometheus + Grafana** for real-time monitoring of **database metrics, cluster health, and resource usage**.
- Implement **ELK (Elasticsearch, Logstash, Kibana)** for centralized logging.
- Set up **alerts** for performance degradation, disk usage, high latency, and failures.

### High Availability & Scalability
- Implement **VerticaAutoscaler** for Vertica pods to enable orizontal Pod Autoscaler (HPA).
- Enable cluster autoscaling using tools like **Karpenter** for efficient node provisioning.

### Backup & Disaster Recovery
- Automate kubernetes resources backups using tools like velero.
- Implement disaster recovery strategies, including:
  - Cross-region Replication for s3.
  - Failover mechanisms to minimize downtime in case of failures.

### Security Enhancements
- Enforce **Network Policies** for controlled traffic flow.
- Implement **central secret management** solutions such as HashiCorp Vault or AWS Secrets Manager to securely store and manage sensitive credentials.
- Use **certificate manager** tools like cert-manager for automated certificate management and renewal to enhance security for TLS communication.

### CI/CD Pipeline Integration
- Automate deployments using **GitLab CI/CD** or **GitHub Actions** or **ArgoCD**.
- Consider **Terraform automation** (e.g., **Atlantis**) to review and apply changes.
- Manage **Helm charts** via Chart Museum for version control.

## Conclusion
This solution provides an automated and scalable approach to deploying **Vertica on AWS EKS** with Terraform and Helm. Future enhancements can further improve security, monitoring, and resilience.

