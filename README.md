# ECR Template
    This template will create EC2 KeyPair which can attach to EC2 Instance.

# How to deploy this stack?

```bash
# Execute the core BucketAv stack
./bucketav-s3-clamav-deployment.sh <<Environment Name>>

# Execute the stack for creating the S3 bucket and upload a core BucketAv template
./bucketav-s3-deployment.sh <<Environment Name>>

# Execute the script for creating DNS configration for Add-On API Sync
./sync-api-dns-config-deployment.sh <<Environment Name>>

```