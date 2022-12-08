
-- Create tables 
-- Here we create both the tables that will be used in the application and the tables that will be used to store the change tracking data.
create table triggers (trigger_id int primary key, trigger_name varchar(40), update_time datetime, trigger_state int);

create table trigger_history (id UNIQUEIDENTIFIER PRIMARY KEY,trigger_id int, trigger_name varchar(40), update_time datetime, trigger_state int);

-- Configure the database to use change tracking
ALTER DATABASE [control]
SET CHANGE_TRACKING = ON
(CHANGE_RETENTION = 2 DAYS, AUTO_CLEANUP = ON);

-- Enable change tracking on the table
ALTER TABLE [trigger]
ENABLE CHANGE_TRACKING;

-- Create a single trigger to insert data into the trigger table
insert into triggers values (1, 'site-1', '2022-12-06 12:00:00', 0);

-- Create multiple triggers to insert data into the trigger table
DECLARE @i int = 0
WHILE @i < 200 
BEGIN
    SET @i = @i + 1
    insert into triggers values (@i, concat('site-',@i), '2022-12-06 12:00:00', 0);
END

-- Update exsiting triggers to generate change tracking data (in single)
update triggers set trigger_state = 2 where update_time = '2022-12-06 12:00:00'

-- Verify trigger history
select trigger_name, count(*)
from [dbo].[trigger_history]
group by trigger_name

select * from triggers

truncate table trigger_history
truncate table triggers


