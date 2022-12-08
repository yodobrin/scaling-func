using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Azure.WebJobs.Extensions.Sql;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using System.Collections.Generic;
using System.Linq;

namespace scaling
{
    public class TriggerDetails
    {
        public Guid Id { get; set; }
        public int? trigger_id { get; set; }
        public string trigger_name { get; set; }
        public System.DateTime update_time { get; set; }
        public int? trigger_state { get; set; }
        
    }
    
    public static class ControlTrigger
    {
        // This function will get triggered/executed when a new item is written
        [FunctionName("ControlTrigger")]
        public static void Run(
            [SqlTrigger("[triggers]", ConnectionStringSetting = "SqlConnectionString")]
            IReadOnlyList<SqlChange<TriggerDetails>> changes,
            [Sql("dbo.trigger_history", ConnectionStringSetting = "SqlConnectionString")] IAsyncCollector<TriggerDetails> triggerHistory,
            ILogger logger)
        {
            logger.LogInformation($"Sql Trigger got: {changes.Count}");
            string funcInstance = GetRandomString(5); // generate a random string to identify which instance of the function processed the trigger
            foreach (SqlChange<TriggerDetails> change in changes)
             {
                 TriggerDetails trigger = change.Item;
                 // do something with the item
                 logger.LogInformation($"Change operation: {change.Operation}");
                 logger.LogInformation($"Id: {trigger.trigger_id}, Name: {trigger.trigger_name}, Update Time: {trigger.update_time}, Trigger State: {trigger.trigger_state}");
                 // add to history table
                 trigger.Id = Guid.NewGuid();
                 trigger.trigger_state = 10; // set to 10 to indicate that the trigger has been processed
                 trigger.trigger_name = funcInstance; // add the function instance to the site name to identify which instance of the function processed the trigger
                 triggerHistory.AddAsync(trigger);
             }
             triggerHistory.FlushAsync();

        }
        // generate a random string to identify which instance of the function processed the trigger
        private static string GetRandomString(int length)
        {
            const string chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
            Random random = new Random();
            return new string(Enumerable.Repeat(chars, length)
              .Select(s => s[random.Next(s.Length)]).ToArray());
        }
    }
}


