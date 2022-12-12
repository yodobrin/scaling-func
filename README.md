# Scaling Azure Functions - SqlTrigger

This repository contains a sample project that demonstrates how to scale Azure Functions using the SqlTrigger.
The function deployment is done using the vscode extension.

The use case is a triggers processing system. The trigger is stored in a Sql Database and the trigger is processed by a function. The function is triggered by a SqlTrigger. The function handeling is minimalistc, but it does demonstrate how to scale the function, audit triggering process, and using Sql Database as a trigger and output binding.

__This sample will cover the following topics:__

- What are the prerequisites

- Step-by-step instructions to deploy the solution 

- Monitoring scale using LogAnalytics


The layout is as follows:

![image](https://user-images.githubusercontent.com/37622785/206461103-ceae2eeb-bc88-4180-9c78-fa424efbde5b.png)

## Prerequisites

- [Azure Functions Core Tools](https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local#v2)

- [Azure Sql Database](https://docs.microsoft.com/en-us/azure/sql-database/sql-database-get-started-portal)

- [Azure Storage Account](https://docs.microsoft.com/en-us/azure/storage/common/storage-account-create?tabs=azure-portal)

- [Azure function app](https://docs.microsoft.com/en-us/azure/azure-functions/functions-create-first-function-vs-code?pivots=programming-language-csharp)

> Note: The function app must be running on a premium plan.

## Setup

1. Clone the repository

2. Create a resource group

3. Create Azure Sql Database (see prerequisites, you can choose the smallest tier) copy the connection string, you will need it later. 

4. Create both tables in the database (see sql folder)

```sql
create table triggers (trigger_id int primary key, trigger_name varchar(40), update_time datetime, trigger_state int);

create table trigger_history (id UNIQUEIDENTIFIER PRIMARY KEY,trigger_id int, trigger_name varchar(40), update_time datetime, trigger_state int);

```

5. Configure the database and table for change tracking (see sql folder)

```sql
-- Configure the database to use change tracking
ALTER DATABASE [control]
SET CHANGE_TRACKING = ON
(CHANGE_RETENTION = 2 DAYS, AUTO_CLEANUP = ON);

-- Enable change tracking on the table
ALTER TABLE [trigger]
ENABLE CHANGE_TRACKING;
```

6. Open vscode at the folder containing the repository.

7. run the following command in the terminal

```bash
dotnet build
```

This should run without errors. In case you have missing nuget packages, run the following command in the terminal

```bash
dotnet add package Microsoft.Azure.WebJobs.Extensions.Sql
```

Repeat for any other missing package.

8. Using vscode, deploy the function app. Use the 'Advanced' option and follow the wizard. You will need to create a new function app. Make sure to select the premium plan. (EP1 is sufficient) The function app will be created in the resource group you created in step 2. More resources would be created such as storage account and app insights.

9. Configure the function app. You will need to configure the following settings:

- SqlConnectionString: The connection string to the database you created in step 3.

- Sql_Trigger_BatchSize: based on the number of triggers you want to process in one batch. The default is 100.

- Sql_Trigger_MaxChangesPerWorker: the number of workers that can be created. The default is 1000.

10. You can run this locally using the vscode extension. You will need to configure the following settings in your local.setting.json

```json
{
    "IsEncrypted": false,
    "Values": {
        "AzureWebJobsStorage": "UseDevelopmentStorage=true",
        "FUNCTIONS_WORKER_RUNTIME": "dotnet",
        "SqlConnectionString": "<your db connection string>",
        "Sql_Trigger_BatchSize": "1",
        "Sql_Trigger_MaxChangesPerWorker": "1"
    }
}
```

### Using the Bicep code

The repo also contains bicep code which will create the Sql Server, the control DB, and the FunctionApp. 

1. Clone the repository

2. Navigate to the bicep folder

3. Create a resource group

4. Modify the bicep parameters file and enter the SQL admin credentials.

5. Run the following command in the terminal

```bash
az deployment group create --resource-group <your resource group> --template-file main.bicep --parameters @parame.json
```

6. Continue with step 5 in the previous section.

8. In step 8, use the created FunctionApp which was created by the bicep code.

## Usage

1. Add a trigger to the triggers table. The trigger_state can be 0. The trigger will be processed by the function.

2. The function will process the trigger and update the trigger_history table and set the trigger_state to 10.

3. query the trigger_history table to see the history of the trigger runs. you can use the simple query in the sql folder.

```sql
-- Verify trigger history
select trigger_name, count(*)
from [dbo].[trigger_history]
group by trigger_name
```

## Monitoring

The function app is configured to use LogAnalytics. 

You can use the following query to monitor the number of workers created.

```sql
traces
| where timestamp between (datetime(2022-12-08 8:00) .. datetime(2022-12-08 14:00))
| parse message with "Unprocessed change counts: " pastCounts:string ", " latestCount:int "], worker count: " workers:int *
| where isnotnull(workers)
| project timestamp, workers
| render timechart;
```

Monitoring remaining changes to process

```sql
traces
| where timestamp between (datetime(2022-12-08 8:00) .. datetime(2022-12-08 14:00))
| parse message with "Unprocessed change counts: " pastCounts:string ", " latestCount:int "], worker count: " workers:int *
| where isnotnull(latestCount)
| project timestamp, latestCount
| render timechart;
```

Scaling activities

```sql
traces
| where timestamp between (datetime(2022-12-08 8:00) .. datetime(2022-12-08 14:00))
| parse message with "Requesting " scaleRecommendation ": " *
| where isnotempty(scaleRecommendation)
| project
    timestamp,
    noScale = toint(scaleRecommendation == "no-scaling"),
    scaleOut = toint(scaleRecommendation == "scale-out"),
    scaleIn = toint(scaleRecommendation == "scale-in")
| render timechart;
```

