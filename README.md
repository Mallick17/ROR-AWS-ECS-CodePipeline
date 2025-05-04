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
- The CodePipeline service role has the necessary permissions (including the ecr:DescribeImages permission).
- ECS Task Execution Role: This role needs permissions to:
- Pull images from ECR.
- Write logs to CloudWatch Logs (if you're using logging).
  
- `AWSCodePipelineServiceRole` includes:
  - `ecr:DescribeImages`
  - `ecs:DescribeServices`, `ecs:UpdateService`, etc.

- `ecsTaskExecutionRole` includes:
  - `ecr:GetAuthorizationToken`
  - `logs:CreateLogGroup`, `logs:PutLogEvents`

---

## Phase 4: Test the Pipeline

### Commit a Change
- Push an update to your Ruby on Rails app in the GitHub repository.

### Verify Pipeline Execution
- Monitor progress in the **CodePipeline Console**.
- All stages (Source, Build, Deploy) should complete successfully.

### Check ECS Deployment
- Ensure the ECS service launches the new task with the updated image.

---

## Auto Scaling Recommendation

### Desired Capacity:

* **Current**: 1 task
* **Recommended**: At least **2 tasks** for high availability and fault tolerance.

> Update via ECS Console or CLI to maintain desired capacity.

---


## IAM Roles and Policies given to create the AWS CodePipeline in Detail

### 1. AWSCodePipelineServiceRole-ap-south-1-mallow-ecs-ror-final-pipeline
This is the IAM role assumed by AWS CodePipeline to perform actions on your behalf during the CI/CD process.

<details>
  <summary> Click to view AWSCodePipelineServiceRole-ap-south-1-mallow-ecs-ror-final-pipeline json format</summary>

   
<details>
  <summary>AWSCodePipelineServiceRole-ap-south-1-mallow-ecs-ror-final-pipeline</summary>

### 1. AWSCodePipelineServiceRole-ap-south-1-mallow-ecs-ror-final-pipeline

```json
{
    "Version": "2012-10-17",
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
                "arn:aws:s3:::codepipelinestartertempla-codepipelineartifactsbuc-lkksehyipedk",
                "arn:aws:s3:::codepipeline-ap-south-1-7417d7b4a8e3-4a7d-b09d-2028b1076a80"
            ],
            "Condition": {
                "StringEquals": {
                    "aws:ResourceAccount": "339713104321"
                }
            }
        },
        {
            "Sid": "AllowS3ObjectAccess",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:PutObjectAcl",
                "s3:GetObject",
                "s3:GetObjectVersion"
            ],
            "Resource": [
                "arn:aws:s3:::codepipelinestartertempla-codepipelineartifactsbuc-lkksehyipedk/*",
                "arn:aws:s3:::codepipeline-ap-south-1-7417d7b4a8e3-4a7d-b09d-2028b1076a80/*"
            ],
            "Condition": {
                "StringEquals": {
                    "aws:ResourceAccount": "339713104321"
                }
            }
        }
    ]
}
```
  
</details>

<details>
  <summary>CodePipeline-CodeBuild-ap-south-1-mallow-ecs-ror-final-pipeline</summary>

### 2. CodePipeline-CodeBuild-ap-south-1-mallow-ecs-ror-final-pipeline
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "codebuild:BatchGetBuilds",
                "codebuild:StartBuild",
                "codebuild:BatchGetBuildBatches",
                "codebuild:StartBuildBatch"
            ],
            "Resource": [
                "arn:aws:codebuild:*:339713104321:project/mallow-ecs-ror-final-codebuild"
            ],
            "Effect": "Allow"
        }
    ]
}
```
</details>

### CodePipeline-CodeConnections-ap-south-1-mallow-ecs-ror-final-pipeline

<details>
  <summary>3. CodePipeline-CodeConnections-ap-south-1-mallow-ecs-ror-final-pipeline</summary>

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "codeconnections:UseConnection",
                "codestar-connections:UseConnection"
            ],
            "Resource": [
                "arn:aws:codestar-connections:*:339713104321:connection/e78bca79-a1be-4f00-9f47-58e0d3058c09",
                "arn:aws:codeconnections:*:339713104321:connection/e78bca79-a1be-4f00-9f47-58e0d3058c09"
            ]
        }
    ]
}
```

</details>  


### CodePipeline-ECSDeploy-ap-south-1-mallow-ecs-ror-final-pipeline

<details>
  <summary>4. CodePipeline-ECSDeploy-ap-south-1-mallow-ecs-ror-final-pipeline</summary>

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "TaskDefinitionPermissions",
            "Effect": "Allow",
            "Action": [
                "ecs:DescribeTaskDefinition",
                "ecs:RegisterTaskDefinition"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Sid": "ECSServicePermissions",
            "Effect": "Allow",
            "Action": [
                "ecs:DescribeServices",
                "ecs:UpdateService"
            ],
            "Resource": [
                "arn:aws:ecs:*:339713104321:service/ror-cluster/*"
            ]
        },
        {
            "Sid": "ECSTagResource",
            "Effect": "Allow",
            "Action": [
                "ecs:TagResource"
            ],
            "Resource": [
                "arn:aws:ecs:*:339713104321:task-definition/arn:aws:ecs:ap-south-1:339713104321:task-definition/ror-mallow-task:18:*"
            ],
            "Condition": {
                "StringEquals": {
                    "ecs:CreateAction": [
                        "RegisterTaskDefinition"
                    ]
                }
            }
        },
        {
            "Sid": "IamPassRolePermissions",
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": [
                "arn:aws:iam::339713104321:role/ecsTaskExecutionRole"
            ],
            "Condition": {
                "StringEquals": {
                    "iam:PassedToService": [
                        "ecs.amazonaws.com",
                        "ecs-tasks.amazonaws.com"
                    ]
                }
            }
        }
    ]
}
```

</details> 

### For CodePipeline Role – ECS & ECR permissions:

<details>
  <summary>5. For CodePipeline Role – ECS & ECR permissions:</summary>

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:DescribeServices",
        "ecs:DescribeTaskDefinition",
        "ecs:RegisterTaskDefinition",
        "ecs:UpdateService"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage"
      ],
      "Resource": "*"
    }
  ]
}
```

</details> 

### 6. For CodeBuild Role – ECR Push & ECS optional support

<details>
  <summary>For CodeBuild Role – ECR Push & ECS optional support</summary>

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
```

</details> 

</details> 

### 2. codebuild-ror-app-role
