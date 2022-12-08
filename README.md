# Scaling Azure Functions - SqlTrigger

This repository contains a sample project that demonstrates how to scale Azure Functions using the SqlTrigger.
Deployment is done using the Azure Functions Core Tools, specifically the vscode extension.

The use case is a simple triggers processing system. The trigger is stored in a Sql Database and the trigger is processed by a function. The function is triggered by a SqlTrigger. The function handeling is minimalistc, however it does demonstrate how to:

- Scale the function

- Audit triggering process

- Using Sql Database as a trigger

- Using Sql Database as an output binding


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