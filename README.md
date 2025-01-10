Create an account and root user using radosgw-admin

```
radosgw-admin account create --account-name=polaris
radosgw-admin user create --uid=kb --display-name=polaris-root --account-root --gen-secret --gen-access-key --account-id=<ACCOUND ID>
```

Create IAM/S3 resources using Terraform

```
terraform apply
```

Ceph does not support customer managed policies. If we try to attach a managed policy that Ceph does support using Terraform it will fail because Terraform validates that all policies exist by making GetPolicy calls for validation purposes, and GetPolicy is not a IAM action that Ceph supports yet. We can still attach a managed policy using the AWS CLI:

```
aws iam --profile polaris-root attach-user-policy --user-name catalog_admin --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
```

Start Polaris container
```
export S3_SECRET_KEY=<SECRET KEY>
export S3_ACCESS_KEY=<ACCESS KEY>
export S3_ENDPOINT=<https://s3.example.com>

sudo docker run -p 8181:8181 -d \
  --network polaris \
  --env S3_SECRET_KEY=${S3_SECRET_KEY} \
  --env S3_ACCESS_KEY=${S3_ACCESS_KEY} \
  --env AWS_REGION=default \
  --env AWS_ENDPOINT_URL_STS=${S3_ENDPOINT} \
  localhost:5001/polaris:s3compatible
```

Spark
```
${SPARK_HOME}/bin/spark-sql \
  --packages org.apache.iceberg:iceberg-spark-runtime-3.5_2.12:1.7.1,org.apache.hadoop:hadoop-aws:3.4.0 \
  --conf spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions  \
  --conf spark.sql.catalog.polaris=org.apache.iceberg.spark.SparkCatalog  \
  --conf spark.sql.catalog.polaris.type=rest  \
  --conf spark.sql.catalog.polaris.uri=http://localhost:8181/api/catalog  \
  --conf spark.sql.catalog.polaris.header.X-Iceberg-Access-Delegation=vended-credentials \
  --conf spark.sql.catalog.polaris.token="${REGTEST_ROOT_BEARER_TOKEN:-principal:root;realm:default-realm}" \
  --conf spark.sql.catalog.polaris.warehouse=my-ceph-wh
  --conf spark.sql.defaultCatalog=polaris
```
