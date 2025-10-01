# Variáveis
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

az provider register --namespace Microsoft.Web
az provider register --namespace Microsoft.Insights
az provider register --namespace Microsoft.OperationalInsights
az extension add --name application-insights

# Grupo de Recursos
az group create \
--name $RESOURCE_GROUP_NAME \
--location "$LOCATION"

# Application Insights
az monitor app-insights component create \
  --app $APP_INSIGHTS_NAME \
  --location $LOCATION \
  --resource-group $RESOURCE_GROUP_NAME \
  --application-type web

# Plano App Service
az appservice plan create \
  --name $APP_SERVICE_PLAN \
  --resource-group $RESOURCE_GROUP_NAME \
  --location "$LOCATION" \
  --sku F1 \
  --is-linux

# Criar Web App (Java 17)
az webapp create \
  --name $WEBAPP_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --plan $APP_SERVICE_PLAN \
  --runtime "JAVA:17-java17"

# SQL PaaS
az sql server create \
  --name $SQL_SERVER \
  --resource-group $RESOURCE_GROUP_NAME \
  --location $LOCATION \
  --admin-user $SQL_USER \
  --admin-password $SQL_PASS \
  --enable-public-network true

# Criar Banco de Dados
az sql db create \
  --resource-group $RESOURCE_GROUP_NAME \
  --server $SQL_SERVER \
  --name $SQL_DB \
  --service-objective Basic \
  --backup-storage-redundancy Local \
  --zone-redundant false

# Liberar acesso público (todos os IPs)
az sql server firewall-rule create \
  --resource-group $RESOURCE_GROUP_NAME \
  --server $SQL_SERVER \
  --name liberaGeral \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 255.255.255.255

# Habilita a autenticação Básica (SCM)
az resource update \
--resource-group $RESOURCE_GROUP_NAME \
--namespace Microsoft.Web \
--resource-type basicPublishingCredentialsPolicies \
--name scm \
--parent sites/$WEBAPP_NAME \
--set properties.allow=true

# Recuperar a String de Conexão do Application Insights (assim podemos nos conectar a esse App Insights)
CONNECTION_STRING=$(az monitor app-insights component show \
--app $APP_INSIGHTS_NAME \
--resource-group $RESOURCE_GROUP_NAME \
--query connectionString \
--output tsv)

# Configurar as Variáveis de Ambiente necessárias do nosso App e do Application Insights
az webapp config appsettings set \
--name "$WEBAPP_NAME" \
--resource-group "$RESOURCE_GROUP_NAME" \
--settings \
APPLICATIONINSIGHTS_CONNECTION_STRING="$CONNECTION_STRING" \
ApplicationInsightsAgent_EXTENSION_VERSION="~3" \
XDT_MicrosoftApplicationInsights_Mode="Recommended" \
XDT_MicrosoftApplicationInsights_PreemptSdk="1" \
SPRING_DATASOURCE_URL="jdbc:sqlserver://SQL-server-find-mottu.database.windows.net:1433;databaseName=db-find-mottu;encrypt=true;trustServerCertificate=false;loginTimeout=30" \
SPRING_DATASOURCE_USERNAME="user-find-mottu" \
SPRING_DATASOURCE_PASSWORD="Fiap@2tdsvms" \
SPRING_JPA_DATABASE_PLATFORM="org.hibernate.dialect.SQLServerDialect" \
SPRING_JPA_HIBERNATE_DDL_AUTO="update" \
SPRING_DATASOURCE_DRIVER="com.microsoft.sqlserver.jdbc.SQLServerDriver"

# Reiniciar o Web App
az webapp restart --name $WEBAPP_NAME --resource-group $RESOURCE_GROUP_NAME

# Criar a conexão do nosso Web App com o Application Insights
az monitor app-insights component connect-webapp \
--app $APP_INSIGHTS_NAME \
--web-app $WEBAPP_NAME \
--resource-group $RESOURCE_GROUP_NAME

# Configurar GitHub Actions para Build e Deploy automático
az webapp deployment github-actions add \
  --name $WEBAPP_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --repo $GITHUB_REPO_NAME \
  --branch $BRANCH \
  --login-with-github