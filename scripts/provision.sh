#!/bin/bash
set -e

OWNER="aicha-elouadi"
RG="aelouadiRG"
LOCATION="francecentral"

TAGS="managed_by=cli environment=tp owner=${OWNER}"

VNET_NAME="vnet-${OWNER}-cli"
NSG_NAME="nsg-frontend-${OWNER}-cli"
NIC_NAME="nic-test-${OWNER}-cli"

echo "OWNER     = $OWNER"
echo "RG        = $RG"
echo "VNET_NAME = $VNET_NAME"
echo "NSG_NAME  = $NSG_NAME"
echo "NIC_NAME  = $NIC_NAME"

echo ""
echo "Création du VNet..."

az network vnet create \
  --name "$VNET_NAME" \
  --resource-group "$RG" \
  --location "$LOCATION" \
  --address-prefix "10.0.0.0/16" \
  --tags $TAGS

echo ""
echo "Création du subnet frontend..."

az network vnet subnet create \
  --name "subnet-frontend" \
  --vnet-name "$VNET_NAME" \
  --resource-group "$RG" \
  --address-prefix "10.0.1.0/24"

echo ""
echo "Création du subnet backend..."

az network vnet subnet create \
  --name "subnet-backend" \
  --vnet-name "$VNET_NAME" \
  --resource-group "$RG" \
  --address-prefix "10.0.2.0/24"

echo ""
echo "Création du NSG..."

az network nsg create \
  --name "$NSG_NAME" \
  --resource-group "$RG" \
  --location "$LOCATION" \
  --tags $TAGS

echo ""
echo "Observation des règles NSG par défaut..."

az network nsg show \
  --name "$NSG_NAME" \
  --resource-group "$RG" \
  --query "defaultSecurityRules[].{Nom:name, Priorite:priority, Direction:direction, Action:access, Port:destinationPortRange}" \
  --output table

echo ""
echo "Ajout règle HTTP..."

az network nsg rule create \
  --name "Allow-HTTP" \
  --nsg-name "$NSG_NAME" \
  --resource-group "$RG" \
  --priority 100 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefix "*" \
  --source-port-range "*" \
  --destination-address-prefix "*" \
  --destination-port-range "80" \
  --description "Autoriser le trafic HTTP entrant"

echo ""
echo "Ajout règle HTTPS..."

az network nsg rule create \
  --name "Allow-HTTPS" \
  --nsg-name "$NSG_NAME" \
  --resource-group "$RG" \
  --priority 110 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefix "*" \
  --source-port-range "*" \
  --destination-address-prefix "*" \
  --destination-port-range "443" \
  --description "Autoriser le trafic HTTPS entrant"

echo ""
echo "Ajout règle Deny-All-Inbound..."

az network nsg rule create \
  --name "Deny-All-Inbound" \
  --nsg-name "$NSG_NAME" \
  --resource-group "$RG" \
  --priority 4000 \
  --direction Inbound \
  --access Deny \
  --protocol "*" \
  --source-address-prefix "*" \
  --source-port-range "*" \
  --destination-address-prefix "*" \
  --destination-port-range "*" \
  --description "Bloquer tout autre trafic entrant"

echo ""
echo "Vérification des règles personnalisées..."

az network nsg rule list \
  --nsg-name "$NSG_NAME" \
  --resource-group "$RG" \
  --query "[].{Nom:name, Priorite:priority, Direction:direction, Action:access, Port:destinationPortRange}" \
  --output table

echo ""
echo "Association du NSG au subnet frontend..."

az network vnet subnet update \
  --name "subnet-frontend" \
  --vnet-name "$VNET_NAME" \
  --resource-group "$RG" \
  --network-security-group "$NSG_NAME"

echo ""
echo "Vérification de l'association NSG au subnet frontend..."

az network vnet subnet show \
  --name "subnet-frontend" \
  --vnet-name "$VNET_NAME" \
  --resource-group "$RG" \
  --query "{Subnet:name, NSG:networkSecurityGroup.id}" \
  --output json

echo ""
echo "Comparaison des deux subnets..."

az network vnet subnet list \
  --vnet-name "$VNET_NAME" \
  --resource-group "$RG" \
  --query "[].{Nom:name, Plage:addressPrefix, NSG:networkSecurityGroup.id}" \
  --output table

echo ""
echo "Création de la NIC de test..."

az network nic create \
  --name "$NIC_NAME" \
  --resource-group "$RG" \
  --location "$LOCATION" \
  --vnet-name "$VNET_NAME" \
  --subnet "subnet-frontend" \
  --tags $TAGS

echo ""
echo "Affichage des règles NSG effectives..."

az network nic list-effective-nsg \
  --name "$NIC_NAME" \
  --resource-group "$RG" \
  --query "effectiveNetworkSecurityGroups[0].effectiveSecurityRules[].{Nom:name, Priorite:priority, Direction:direction, Action:access, Port:destinationPortRanges}" \
  --output table || echo "Impossible d'afficher les règles effectives : la NIC doit être attachée à une VM démarrée."

echo ""
echo "Provisionnement terminé."