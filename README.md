Create an account and root user using radosgw-admin

```
radosgw-admin account create --account-name=polaris
radosgw-admin user create --uid=polaris \
                          --display-name=polaris-root \
                          --account-root \
                          --gen-secret \
                          --gen-access-key \
                          --account-id=<ACCOUNT ID>
```

Create IAM/S3 resources using Terraform

```
terraform init
terraform plan
terraform apply
```

Start Polaris container
```
export S3_SECRET_KEY=<SECRET KEY>
export S3_ACCESS_KEY=<ACCESS KEY>
export S3_ENDPOINT=<https://s3.example.com>
export S3_LOCATION=s3://polaris

sudo docker run -p 8181:8181 -d \
  --network polaris \
  --env S3_SECRET_KEY=${S3_SECRET_KEY} \
  --env S3_ACCESS_KEY=${S3_ACCESS_KEY} \
  --env AWS_REGION=default \
  --env AWS_ENDPOINT_URL_STS=${S3_ENDPOINT} \
  icr.io/ceph-polaris/polaris
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

Create table query
```
CREATE TABLE prod.db.foo (
    id bigint NOT NULL COMMENT 'unique id',
    data string)
USING iceberg;
```
