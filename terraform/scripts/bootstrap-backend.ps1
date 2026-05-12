param(
  [Parameter(Mandatory = $true)]
  [string]$BucketName,

  [Parameter(Mandatory = $true)]
  [string]$TableName,

  [string]$Region = "us-east-1"
)

$ErrorActionPreference = "Stop"

if ($Region -eq "us-east-1") {
  aws s3api create-bucket --bucket $BucketName --region $Region | Out-Null
}
else {
  aws s3api create-bucket --bucket $BucketName --region $Region --create-bucket-configuration LocationConstraint=$Region | Out-Null
}

aws s3api put-bucket-versioning --bucket $BucketName --versioning-configuration Status=Enabled | Out-Null
aws s3api put-bucket-encryption --bucket $BucketName --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}' | Out-Null
aws s3api put-public-access-block --bucket $BucketName --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true | Out-Null

aws dynamodb create-table `
  --table-name $TableName `
  --attribute-definitions AttributeName=LockID,AttributeType=S `
  --key-schema AttributeName=LockID,KeyType=HASH `
  --billing-mode PAY_PER_REQUEST `
  --region $Region | Out-Null

Write-Host "Terraform backend is ready."
Write-Host "Bucket: $BucketName"
Write-Host "Lock table: $TableName"
