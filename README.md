# CodePipeline Configuration for ROR Application Deployment

---

## 🗂 Project Structure
- Make sure your Rails app folder looks like this:

```
chat-app/
├── Dockerfile
├── docker-compose.yml
├── .env
├── Gemfile
├── Gemfile.lock
├── config/
│   ├── database.yml
│   └── puma.rb
├── buildspec.yml
├── entrypoint.sh
├── nginx.conf
├── config.ru
├── Rakefile
└── render.yaml

```

---

# CodePipeline Documentation for Ruby on Rails Application Deployment
## Phase 1: Prerequisites 
- _**[Follow ROR-AWS-ECS Repo to create AWS services such as Auto Scaling Group (ASG), Launch Template, Amazon RDS, Amazon ECS (Cluster, Task Definition, Service), Amazon ECR, AWS CodeBuild, and IAM Roles.,](https://github.com/Mallick17/ROR-AWS-ECS)**_

- Before configuring CodePipeline, ensure the following components are in place:

### 1. Existing ECS Setup:
- An **ECS cluster**, **service**, and **task definition** are already configured.
- The ECS **service uses the Fargate launch type** for serverless container orchestration.

### 2. CodeBuild Project:
- A **CodeBuild project** is set up to:
  - Build the Docker image from the Ruby on Rails codebase.
  - Push the image to **Amazon ECR**.
  - Generate the `imagedefinitions.json` file needed by ECS.

### 3. Source Code Repository:
- The Ruby on Rails application code is hosted in a GitHub repository:
  - Example: `Mallick17/ROR-AWS-ECS-CodePipeline`

### 4. IAM Roles:
- `AWSCodePipelineServiceRole`: For CodePipeline to manage AWS services and trigger builds/deployments.
- `ecsTaskExecutionRole`: For ECS Fargate tasks to pull Docker images from ECR and push logs to CloudWatch.

---

## Phase 2: Create the CodePipeline

Follow these steps in the AWS Management Console to set up the pipeline:

### 1. Open the CodePipeline Console

- Navigate to: [AWS CodePipeline Console](https://console.aws.amazon.com/codepipeline/)

---

### 2️. Create a New Pipeline

- Click **"Create pipeline"**.
- On the “Choose pipeline settings” page:
  - **Pipeline name**: `fargate-deployment-pipeline`
  - **Pipeline type**: V2
  - **Service role**: Use existing role  
    `AWSCodePipelineServiceRole-ap-south-1-ror-chat-app-pipeline`
  - **Artifact store**: Choose or create an S3 bucket for storing build artifacts  
    Example: `codepipeline-ap-south-1-7417d7b4a8e3-4a7d-b09d-2028b1076a80`
- Click **"Next"**

---

### 3️. Add a Source Stage

- **Source provider**: AWS CodeConnections
- **ConnectionArn**:  
  `arn:aws:codeconnections:ap-south-1:339713104321:connection/e78bca79-a1be-4f00-9f47-58e0d3058c09`
- **FullRepositoryId**: `Mallick17/ROR-AWS-ECS-CodePipeline`
- **BranchName**: `master`
- **OutputArtifactFormat**: `CODE_ZIP`
- Click **"Next"**

---

### 4️. Add a Build Stage

- **Build provider**: AWS CodeBuild
- **Project name**: `mallow-ecs-ror-final-codebuild` (select existing CodeBuild project)
- Click **"Next"**

---

### 5️. Add a Deploy Stage

- **Deploy provider**: Amazon ECS
- **Cluster name**: `ror-cluster`
- **Service name**: Select your existing ECS service
- **Image definitions file**: `imagedefinitions.json`
- Click **"Next"**

---

### 6️. Review and Create

- Review all settings.
- Click **"Create pipeline"**

---

## Phase 3: Verify Configurations

Ensure the following components are configured correctly:

### 🔧 CodeBuild

- `buildspec.yml` file must:
  - Build the Docker image.
  - Push it to Amazon ECR.
  - Generate `imagedefinitions.json`.

- CodeBuild service role has the correct permissions for:
  - ECR access (push/pull).
  - CloudWatch logging.
  - Secrets Manager (if used).

---

### 🔧 ECS

- ECS service is running on **Fargate** launch type.
- Task definition:
  - Points to the correct ECR image.
  - Uses the correct execution role: `ecsTaskExecutionRole`.

---

### 🔧 IAM Roles

- `AWSCodePipelineServiceRole` includes:
  - `ecr:DescribeImages`
  - `ecs:DescribeServices`, `ecs:UpdateService`, etc.

- `ecsTaskExecutionRole` includes:
  - `ecr:GetAuthorizationToken`
  - `logs:CreateLogGroup`, `logs:PutLogEvents`

---

## Phase 4: Test the Pipeline

### ✅ Commit a Change
- Push an update to your Ruby on Rails app in the GitHub repository.

### ✅ Verify Pipeline Execution
- Monitor progress in the **CodePipeline Console**.
- All stages (Source, Build, Deploy) should complete successfully.

### ✅ Check ECS Deployment
- Ensure the ECS service launches the new task with the updated image.

---

## IAM Roles and Policies

### 1. CodePipeline Service Role (S3 Access)
```json
{
  "Statement": [
    {
      "Sid": "AllowS3BucketAccess",
      "Effect": "Allow",
      "Action": [
        "s3:GetBucketVersioning",
        "s3:GetBucketAcl",
        "s3:GetBucketLocation"
      ],
      "Resource": [
        "arn:aws:s3:::codepipeline-ap-south-1-7417d7b4a8e3-4a7d-b09d-2028b1076a80"
      ]
    },
    {
      "Sid": "AllowS3ObjectAccess",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject"
      ],
      "Resource": [
        "arn:aws:s3:::codepipeline-ap-south-1-7417d7b4a8e3-4a7d-b09d-2028b1076a80/*"
      ]
    }
  ]
}
````

### 2. CodePipeline → CodeBuild Permissions

```json
{
  "Action": [
    "codebuild:StartBuild",
    "codebuild:BatchGetBuilds"
  ],
  "Resource": [
    "arn:aws:codebuild:*:339713104321:project/mallow-ecs-ror-final-codebuild"
  ],
  "Effect": "Allow"
}
```

### 3. CodePipeline → CodeConnections Permissions

```json
{
  "Action": [
    "codeconnections:UseConnection",
    "codestar-connections:UseConnection"
  ],
  "Resource": [
    "arn:aws:codestar-connections:*:339713104321:connection/e78bca79-a1be-4f00-9f47-58e0d3058c09"
  ],
  "Effect": "Allow"
}
```

### 4. CodePipeline → ECS Deployment

```json
{
  "Statement": [
    {
      "Action": [
        "ecs:DescribeTaskDefinition",
        "ecs:RegisterTaskDefinition",
        "ecs:UpdateService"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "iam:PassRole"
      ],
      "Resource": "arn:aws:iam::339713104321:role/ecsTaskExecutionRole"
    }
  ]
}
```

### 5. CodePipeline Role – ECS & ECR Permissions

```json
{
  "Action": [
    "ecs:DescribeServices",
    "ecs:UpdateService",
    "ecr:GetAuthorizationToken",
    "ecr:BatchGetImage"
  ],
  "Effect": "Allow",
  "Resource": "*"
}
```

---

## CodeBuild Role: ECR Push & Logging

```json
{
  "Action": [
    "ecr:PutImage",
    "ecr:InitiateLayerUpload",
    "logs:CreateLogGroup",
    "logs:PutLogEvents"
  ],
  "Effect": "Allow",
  "Resource": "*"
}
```

---

## Additional IAM Role: `codebuild-ror-app-role`

Attached managed policies:

* `AmazonEC2ContainerRegistryPowerUser`
* `AmazonECS_FullAccess`
* `AmazonRDSReadOnlyAccess`
* `AmazonVPCFullAccess`
* `AWSCodeBuildAdminAccess`
* `CloudWatchLogsFullAccess`
* `SecretsManagerReadWrite`
* Custom CodeBuild policies:

  * `CodeBuildBasePolicy-codebuild-ror-app-role-ap-south-1`
  * `CodeBuildSecretsManagerPolicy-chat-app-ap-south-1`

---

## Auto Scaling Recommendation

### Desired Capacity:

* **Current**: 1 task
* **Recommended**: At least **2 tasks** for high availability and fault tolerance.

> Update via ECS Console or CLI to maintain desired capacity.

---




