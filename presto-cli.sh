#!/bin/bash
#

polaris principal create --client-id "alice" --property admin=true alice
polaris principal create --client-id "bob" bob
polaris principal create --client-id "mark" mark

for role in catalog_admin data_engineer data_scientist;do
  polaris principal-roles create $role
done

polaris principal-roles grant --principal alice catalog_admin
polaris principal-roles grant --principal bob data_engineer
polaris principal-roles grant --principal mark data_scientist

for catalog in bronze silver gold;do
  polaris catalog-roles create --catalog $catalog catalog_admin
done

polaris catalog-roles create --catalog bronze catalog_contributor
polaris catalog-roles create --catalog silver data_admin
polaris catalog-roles create --catalog gold data_admin
polaris catalog-roles create --catalog gold catalog_reader

for catalog in bronze silver gold;do
  polaris catalog-roles grant --catalog $catalog --principal_role data_engineer data_admin
done

polaris catalog-roles grant --catalog gold --principal_role data_scientist catalog_reader

echo "Creating catalog_admin grants"
for catalog in bronze silver gold;do
  polaris privileges \
    catalog \
    grant \
    --catalog $catalog \
    --catalog-role catalog_admin \
    TABLE_FULL_METADATA

  polaris privileges \
    namespace \
    grant \
    --catalog $catalog \
    --catalog-role catalog_admin \
    NAMESPACE_FULL_METADATA
done

echo "Creating catalog_contributor grants"
for priv in NAMESPACE_FULL_METADATA TABLE_FULL_METADATA TABLE_READ_DATA TABLE_WRITE_DATA;do
  polaris privileges \
    catalog \
    grant \
    --catalog bronze \
    --catalog-role catalog_contributor \
    ${priv}
done

echo "Creating data_admin grants for silver and gold catalogs"
for zone in silver gold;do
  for priv in  NAMESPACE_FULL_METADATA TABLE_FULL_METADATA TABLE_READ_DATA TABLE_WRITE_DATA;do
    polaris privileges \
      catalog \
      grant \
      --catalog $zone \
      --catalog-role data_admin \
      ${priv}
  done
done

echo "Creating catalog_reader grants for gold catalog"
for priv in NAMESPACE_LIST NAMESPACE_READ_PROPERTIES TABLE_LIST TABLE_READ_PROPERTIES TABLE_READ_DATA;do
  polaris privileges \
    catalog \
    grant \
    --catalog gold \
    --catalog-role catalog_reader \
    ${priv}
done
