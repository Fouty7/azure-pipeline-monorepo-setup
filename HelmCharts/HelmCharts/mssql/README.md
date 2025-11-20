#Persistence
#By default the chart creates a Persistent Volume Claim that triggers dynamic provisioning of an Azure Disk.
#Data is stored under var/opt/mssql in the container and survives pod restarts & upgrades.

#Connecting to SQL Server

# Forward Local Port to the clusterIP Service
#Kubectl port-forward svc/mssql 1433:1433 -n data
# Connect with Azure Data Studio, SSMS, sqlcmd, etc.
#sqlcmd -S localhost -U sa -P '<YourStrong!Password>' -Q 'SELECT @@VERSION'