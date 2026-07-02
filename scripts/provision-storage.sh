#!/bin/bash
set -e

OWNER="aicha-elouadi"
RG="aelouadiRG"
LOCATION="francecentral"

TAGS="managed_by=cli environment=tp owner=${OWNER}"

SA_NAME="st${OWNER//-/}cli"

echo "OWNER   = $OWNER"
echo "RG      = $RG"
echo "SA_NAME = $SA_NAME"

echo ""
echo "Vérification du resource group..."

az group show \
  --name "$RG" \
  --output table

echo ""
echo "Création du Storage Account..."

az storage account create \
  --name "$SA_NAME" \
  --resource-group "$RG" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --allow-blob-public-access true \
  --tags $TAGS

echo ""
echo "Vérification du Storage Account..."

az storage account show \
  --name "$SA_NAME" \
  --resource-group "$RG" \
  --query "{nom:name, region:location, sku:sku.name, statut:provisioningState}" \
  --output table

echo ""
echo "Récupération de la connection string..."

export AZURE_STORAGE_CONNECTION_STRING=$(az storage account show-connection-string \
  --name "$SA_NAME" \
  --resource-group "$RG" \
  --query connectionString \
  --output tsv)

echo "Connection string récupérée."

echo ""
echo "Création du conteneur privé api-logs..."

az storage container create \
  --name "api-logs" \
  --public-access off

echo ""
echo "Création du conteneur public api-config..."

az storage container create \
  --name "api-config" \
  --public-access blob

echo ""
echo "Vérification des conteneurs..."

az storage container list \
  --query "[].{Nom:name, Acces:properties.publicAccess}" \
  --output table

echo ""
echo "Création du fichier de log..."

cat > access-log.txt << 'EOF'
2024-06-18 09:12:33 - GET /api/hello - 200 OK - 45ms - App Service
2024-06-18 09:12:47 - GET /api/hello - 200 OK - 12ms - Azure Functions
2024-06-18 09:13:01 - GET /api/hello - 200 OK - 38ms - Container Instances
EOF

echo ""
echo "Upload du fichier access-log.txt dans api-logs..."

az storage blob upload \
  --container-name "api-logs" \
  --file "access-log.txt" \
  --name "access-log.txt" \
  --overwrite

echo ""
echo "Vérification du blob privé..."

az storage blob list \
  --container-name "api-logs" \
  --query "[].{Nom:name, Taille:properties.contentLength, Date:properties.lastModified}" \
  --output table

echo ""
echo "Test d'accès public au blob privé..."

PRIVATE_URL=$(az storage blob url \
  --container-name "api-logs" \
  --name "access-log.txt" \
  --output tsv)

echo "URL privée testée : $PRIVATE_URL"
curl -s "$PRIVATE_URL" || true

echo ""
echo "Génération d'une SAS URL valable 1 heure..."

EXPIRY=$(date -u -d "+1 hour" '+%Y-%m-%dT%H:%MZ')

SAS_URL=$(az storage blob generate-sas \
  --container-name "api-logs" \
  --name "access-log.txt" \
  --permissions r \
  --expiry "$EXPIRY" \
  --full-uri \
  --output tsv)

echo "SAS URL générée."
echo "Test de lecture via SAS URL :"
curl -s "$SAS_URL"

echo ""
echo "Création du fichier config.json..."

cat > config.json << 'EOF'
{
  "app": "AzureTech",
  "version": "1.0",
  "environment": "production",
  "endpoints": ["/api/hello", "/api/status"]
}
EOF

echo ""
echo "Upload de config.json dans api-config..."

az storage blob upload \
  --container-name "api-config" \
  --file "config.json" \
  --name "config.json" \
  --content-type "application/json" \
  --overwrite

echo ""
echo "Test d'accès public au fichier config.json..."

CONFIG_URL=$(az storage blob url \
  --container-name "api-config" \
  --name "config.json" \
  --output tsv)

echo "URL publique : $CONFIG_URL"
curl -s "$CONFIG_URL"

echo ""
echo "Liste des blobs dans api-logs..."

az storage blob list \
  --container-name "api-logs" \
  --query "[].{Nom:name, Taille:properties.contentLength}" \
  --output table

echo ""
echo "Liste des blobs dans api-config..."

az storage blob list \
  --container-name "api-config" \
  --query "[].{Nom:name, Taille:properties.contentLength}" \
  --output table

echo ""
echo "Options de redondance principales pour un Storage Account :"

echo "Standard_LRS  - Redondance locale"
echo "Standard_ZRS  - Redondance par zones"
echo "Standard_GRS  - Redondance géographique"
echo "Standard_GZRS - Redondance géographique + zones"
echo "Premium_LRS   - Premium avec redondance locale"

echo ""
echo "TP Stockage terminé."