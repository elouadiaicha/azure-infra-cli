# TP Azure - Module 5 : Hébergement d'une API

## Objectif

Comparer trois solutions d'hébergement Azure en déployant une API simple sur :

- Azure App Service (PaaS)
- Azure Functions (Serverless)
- Azure Container Instances (ACI)

---

## Partie 1 - Azure App Service

### Service utilisé
Azure App Service (PaaS)

### Résultat

Déploiement d'une API PHP renvoyant un objet JSON.

URL :
https://api-appservice-aicha.azurewebsites.net

---

## Partie 2 - Azure Functions

### Service utilisé
Azure Functions (Serverless)

### Résultat

Déploiement d'une fonction HTTP en Python 3.11.

URL :
https://api-func-aicha...azurewebsites.net/api/hello

---

## Partie 3 - Azure Container Instances

### Service utilisé
Azure Container Instances (ACI)

### Résultat

Déploiement du conteneur Docker fourni par Microsoft.

URL :
http://api-aci-aicha....francecentral.azurecontainer.io

---

# Comparaison

| Critère | App Service | Azure Functions | Container Instances |
|----------|-------------|-----------------|---------------------|
| Temps de déploiement | ~2 min | ~2 min | ~1 min |
| Code déployé | PHP | Python | Image Docker |
| Facturation | Plan mensuel | À l'exécution | À la seconde |
| Scale automatique | Oui | Oui | Non |
| Gestion de l'OS | Azure | Azure | Azure |
| Gestion du runtime | Azure | Azure | Utilisateur |

---

# Conclusion

Pour une startup avec un trafic imprévisible et un budget limité, Azure Functions est la solution la plus adaptée.

Elle permet :

- une facturation uniquement à l'exécution ;
- une montée en charge automatique ;
- aucun serveur à administrer ;
- un coût réduit lorsque l'application reçoit peu de trafic.

---

## Nettoyage

Les ressources suivantes ont été supprimées après les tests :

- Azure Container Instance
- Azure Function App
- Azure App Service