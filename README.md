<a id="readme-top"></a>

# 📱 Challange - Mottu - DevOps - Web App Service - Find Mottu

## 🧑‍🤝‍🧑 Informações dos Contribuintes

| Nome | Matricula | Turma |
| :------------: | :------------: | :------------: |
| Felipe Nogueira Ramon | 555335 | 2TDSPH |
| Pedro Herique Vasco Antonieti | 556253 | 2TDSPH |
<p align="right"><a href="#readme-top">Voltar ao topo</a></p>

## 🚩 Características

Find Mottu é uma solução completa para gestão de frotas de motocicletas, desenvolvida com tecnologias modernas e boas práticas de desenvolvimento.

O sistema oferece uma API RESTful robusta, construída em Java com Spring Boot, que garante escalabilidade, segurança e integração com diferentes serviços.

Complementando a API, o projeto também disponibiliza um Web App administrativo, desenvolvido com Spring Web e Thymeleaf, proporcionando uma interface responsiva, intuitiva e otimizada para a gestão de usuários, filiais e motocicletas.


## 🎥 Youtube

Apresentação do projeto no Youtube: https://www.youtube.com/watch?v=KwvSilYo04g
<p align="right"><a href="#readme-top">Voltar ao topo</a></p>


## 🛠️ Tecnologias Utilizadas

![Apache Maven](https://img.shields.io/badge/Apache%20Maven-C71A36?style=for-the-badge&logo=Apache%20Maven&logoColor=white)
![Java](https://img.shields.io/badge/java-%23ED8B00.svg?style=for-the-badge&logo=openjdk&logoColor=white)
![Swagger](https://img.shields.io/badge/-Swagger-%23Clojure?style=for-the-badge&logo=swagger&logoColor=white)

<p align="right"><a href="#readme-top">Voltar ao topo</a></p>

## ☁️ Deploy Find Mottu na Azure

Este repositório contém os scripts e instruções necessários para realizar o **deploy do projeto [java-find-mottu](https://github.com/P3terHenry/java-find-mottu)** na Azure utilizando **Azure CLI** e **GitHub Actions**.

---

## ⚙️ Variáveis de Ambiente

Antes de rodar os comandos, configure as variáveis:

```sh
RESOURCE_GROUP_NAME="rg-devops-find-mottu"
LOCATION="brazilsouth"
APP_SERVICE_PLAN="plan-find-mottu"
WEBAPP_NAME="app-find-mottu"
APP_INSIGHTS_NAME="ai-find-mottu"
SQL_SERVER="sql-server-find-mottu"
SQL_DB="db-find-mottu"
SQL_USER="user-find-mottu"
SQL_PASS="Fiap@2tdsvms"
GITHUB_REPO_NAME="P3terHenry/java-find-mottu"
BRANCH="main"
```

---

## 🚀 Etapas de Deploy

### 1️⃣ Providers e Extensões

```sh
az provider register --namespace Microsoft.Web
az provider register --namespace Microsoft.Insights
az provider register --namespace Microsoft.OperationalInsights
az extension add --name application-insights
```

### 2️⃣ Criar Grupo de Recursos

```sh
az group create \
    --name $RESOURCE_GROUP_NAME \
    --location "$LOCATION"
```

### 3️⃣ Application Insights

```sh
az monitor app-insights component create \
    --app $APP_INSIGHTS_NAME \
    --location $LOCATION \
    --resource-group $RESOURCE_GROUP_NAME \
    --application-type web
```

### 4️⃣ Plano App Service

```sh
az appservice plan create \
    --name $APP_SERVICE_PLAN \
    --resource-group $RESOURCE_GROUP_NAME \
    --location "$LOCATION" \
    --sku F1 \
    --is-linux
```

### 5️⃣ Criar Web App (Java 17)

```sh
az webapp create \
    --name $WEBAPP_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --plan $APP_SERVICE_PLAN \
    --runtime "JAVA:17-java17"
```

### 6️⃣ Banco de Dados SQL Server

Criação do SQL Server:
```sh
az sql server create \
    --name $SQL_SERVER \
    --resource-group $RESOURCE_GROUP_NAME \
    --location $LOCATION \
    --admin-user $SQL_USER \
    --admin-password $SQL_PASS \
    --enable-public-network true
```

Criação do Database dentro do SQL Server:
```sh
az sql db create \
    --resource-group $RESOURCE_GROUP_NAME \
    --server $SQL_SERVER \
    --name $SQL_DB \
    --service-objective Basic \
    --backup-storage-redundancy Local \
    --zone-redundant false
```

Liberar acesso público para todos os IPs no SQL Server:
```sh
az sql server firewall-rule create \
    --resource-group $RESOURCE_GROUP_NAME \
    --server $SQL_SERVER \
    --name liberaGeral \
    --start-ip-address 0.0.0.0 \
    --end-ip-address 255.255.255.255
```

### 7️⃣ Habilitar autenticação básica (SCM)

```sh
az resource update \
    --resource-group $RESOURCE_GROUP_NAME \
    --namespace Microsoft.Web \
    --resource-type basicPublishingCredentialsPolicies \
    --name scm \
    --parent sites/$WEBAPP_NAME \
    --set properties.allow=true
```

### 8️⃣ Configurar Variáveis de Ambiente

Recuperar a string do Application Insights:

```sh
CONNECTION_STRING=$(az monitor app-insights component show \
--app $APP_INSIGHTS_NAME \
--resource-group $RESOURCE_GROUP_NAME \
--query connectionString \
--output tsv)
```

Configurar App Settings no WebApp:

```sh
az webapp config appsettings set \
    --name "$WEBAPP_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --settings \
    APPLICATIONINSIGHTS_CONNECTION_STRING="$CONNECTION_STRING" \
    ApplicationInsightsAgent_EXTENSION_VERSION="~3" \
    XDT_MicrosoftApplicationInsights_Mode="Recommended" \
    XDT_MicrosoftApplicationInsights_PreemptSdk="1" \
    SPRING_DATASOURCE_URL="jdbc:sqlserver://sql-server-find-mottu.database.windows.net:1433;databaseName=db-find-mottu;encrypt=true;trustServerCertificate=false;loginTimeout=30" \
    SPRING_DATASOURCE_USERNAME="user-find-mottu" \
    SPRING_DATASOURCE_PASSWORD="Fiap@2tdsvms" \
    SPRING_JPA_DATABASE_PLATFORM="org.hibernate.dialect.SQLServerDialect" \
    SPRING_JPA_HIBERNATE_DDL_AUTO="update" \
    SPRING_DATASOURCE_DRIVER="com.microsoft.sqlserver.jdbc.SQLServerDriver"
```

Reiniciar o WebApp:

```sh
az webapp restart --name $WEBAPP_NAME --resource-group $RESOURCE_GROUP_NAME
```

Conectar o Web App com o App Insights:

```sh
az monitor app-insights component connect-webapp \
    --app $APP_INSIGHTS_NAME \
    --web-app $WEBAPP_NAME \
    --resource-group $RESOURCE_GROUP_NAME
```

### 9️⃣ Configurar GitHub Actions

```sh
az webapp deployment github-actions add \
    --name $WEBAPP_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --repo $GITHUB_REPO_NAME \
    --branch $BRANCH \
    --login-with-github
```

---

## 🔑 Configurar Secrets no GitHub

1. Vá em Settings → Secrets and variables → Actions
2. Clique em New repository secret
3. Adicione os secrets abaixo (um de cada vez):

```ini
SPRING_DATASOURCE_URL=jdbc:sqlserver://sql-server-find-mottu.database.windows.net:1433;databaseName=db-find-mottu;encrypt=true;trustServerCertificate=false;loginTimeout=30;
SPRING_DATASOURCE_USERNAME=user-find-mottu
SPRING_DATASOURCE_PASSWORD=Fiap@2tdsvms
SPRING_JPA_DATABASE_PLATFORM=org.hibernate.dialect.SQLServerDialect
SPRING_JPA_HIBERNATE_DDL_AUTO=update
SPRING_DATASOURCE_DRIVER=com.microsoft.sqlserver.jdbc.SQLServerDriver
```

No arquivo **.github/workflows/deploy.yml**:

```yml
env:
  SPRING_DATASOURCE_URL: ${{ secrets.SPRING_DATASOURCE_URL }}
  SPRING_DATASOURCE_USERNAME: ${{ secrets.SPRING_DATASOURCE_USERNAME }}
  SPRING_DATASOURCE_PASSWORD: ${{ secrets.SPRING_DATASOURCE_PASSWORD }}
  SPRING_JPA_DATABASE_PLATFORM: ${{ secrets.SPRING_JPA_DATABASE_PLATFORM }}
  SPRING_JPA_HIBERNATE_DDL_AUTO: ${{ secrets.SPRING_JPA_HIBERNATE_DDL_AUTO }}
  SPRING_DATASOURCE_DRIVER: ${{ secrets.SPRING_DATASOURCE_DRIVER }}
```

---

✅ Pronto! Agora o deploy será feito automaticamente via GitHub Actions sempre que houver push na branch main.

<p align="right"><a href="#readme-top">Voltar ao topo</a></p>