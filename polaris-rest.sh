#!/bin/bash

curl -s -i -X POST \
           -H "Authorization: Bearer ${POLARIS_BEARER_TOKEN:-principal:root;realm:default-realm}" \
           -H 'Accept: application/json' \
           -H 'Content-Type: application/json' \
           http://${POLARIS_HOST:-localhost}:8181/api/management/v1/catalogs \
           -d "{
                \"name\": \"my-ceph-wh\",
                \"id\": 100,
                \"type\": \"INTERNAL\",
                \"readOnly\": false,
                \"properties\": {
                  \"default-base-location\": \"${S3_LOCATION}\"
                 },
                \"storageConfigInfo\": {
                  \"storageType\": \"S3_COMPATIBLE\",
                  \"allowedLocations\": [\"${S3_LOCATION}/\"],
                  \"s3.region\": \"default\",
                  \"s3.endpoint\": \"https://s3.cephlabs.com\",
                  \"s3.credentials.catalog.accessKeyId\": \"S3_ACCESS_KEY\",
                  \"s3.credentials.catalog.secretAccessKey\": \"S3_SECRET_KEY\",
                  \"s3.roleArn\": \"arn:aws:iam::RGW25531238860968914:role/polaris/catalog/client\"
                }
              }"

curl -i -X PUT \
        -H "Authorization: Bearer ${POLARIS_BEARER_TOKEN:-principal:root;realm:default-realm}" \
        -H 'Accept: application/json' \
        -H 'Content-Type: application/json' \
        http://${POLARIS_HOST:-localhost}:8181/api/management/v1/catalogs/my-ceph-wh/catalog-roles/catalog_admin/grants \
        -d '{
             "type": "catalog",
             "privilege": "TABLE_WRITE_DATA"
            }'

curl -i -X PUT \
        -H "Authorization: Bearer ${POLARIS_BEARER_TOKEN:-principal:root;realm:default-realm}" \
        -H 'Accept: application/json' \
        -H 'Content-Type: application/json' \
        http://${POLARIS_HOST:-localhost}:8181/api/management/v1/principal-roles/service_admin/catalog-roles/my-ceph-wh \
        -d '{
              "name": "catalog_admin"
            }'
