list @AGS_GAME_AUDIENCE.RAW.UNI_KISHORE_PIPELINE;

create or replace TABLE AGS_GAME_AUDIENCE.RAW.PIPELINE_LOGS (
	RAW_LOG VARIANT
);

copy into AGS_GAME_AUDIENCE.RAW.PIPELINE_LOGS
from @AGS_GAME_AUDIENCE.RAW.UNI_KISHORE_PIPELINE
file_format = (format_name=AGS_GAME_AUDIENCE.RAW.FF_JSON_LOGS)
--Force it to load duplicates
--FORCE=TRUE
;

select *
from AGS_GAME_AUDIENCE.RAW.PIPELINE_LOGS;

TRUNCATE TABLE PIPELINE_LOGS;

create or replace view AGS_GAME_AUDIENCE.RAW.PL_LOGS(
	USER_EVENT,
	USER_LOGIN,
	IP_ADDRESS,
	DATETIME_ISO8601,
	RAW_LOG
) as
select
--RAW_LOG:agent::text as AGENT,
RAW_LOG:user_event::text as USER_EVENT
,RAW_LOG:user_login::text as USER_LOGIN
,RAW_LOG:ip_address::text as IP_ADDRESS
--,RAW_LOG:game_subscription_type::text as GAME_SUBSCRIPTION_TYPE
,RAW_LOG:datetime_iso8601::TIMESTAMP_NTZ as DATETIME_ISO8601
,*
from AGS_GAME_AUDIENCE.RAW.PIPELINE_LOGS
where RAW_LOG:agent::text is null;

select *
from AGS_GAME_AUDIENCE.RAW.PL_LOGS;

create or replace task AGS_GAME_AUDIENCE.RAW.LOAD_LOGS_ENHANCED
--USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
schedule='5 Minutes'
--after AGS_GAME_AUDIENCE.RAW.GET_NEW_FILES
as
MERGE INTO ENHANCED.LOGS_ENHANCED e
USING (
SELECT ED_PIPELINE_LOGS.ip_address
, ED_PIPELINE_LOGS.user_login AS GAMER_NAME
, ED_PIPELINE_LOGS.user_event AS GAME_EVENT_NAME
, ED_PIPELINE_LOGS.datetime_iso8601 AS GAME_EVENT_UTC
, city
, region
, country
, timezone AS GAMER_LTZ_NAME
, CONVERT_TIMEZONE ('UTC', timezone, ED_PIPELINE_LOGS.datetime_iso8601) as GAME_EVENT_LTZ
, DAYNAME (GAME_EVENT_LTZ) as DOW_NAME
, TOD_NAME
from AGS_GAME_AUDIENCE.RAW.ED_PIPELINE_LOGS ED_PIPELINE_LOGS
JOIN IPINFO_GEOLOC.demo.location loc 
ON IPINFO_GEOLOC.public.TO_JOIN_KEY(ED_PIPELINE_LOGS.ip_address) = loc.join_key
AND IPINFO_GEOLOC.public.TO_INT(ED_PIPELINE_LOGS.ip_address) 
BETWEEN start_ip_int AND end_ip_int
JOIN ags_game_audience.raw.time_of_day_lu tod
ON HOUR(game_event_ltz) = tod.hour) r
ON r.GAMER_NAME = e.GAMER_NAME
AND r.GAME_EVENT_UTC = e.GAME_EVENT_UTC
AND r.GAME_EVENT_NAME = e.GAME_EVENT_NAME
WHEN NOT MATCHED THEN
INSERT (IP_ADDRESS, GAMER_NAME, GAME_EVENT_NAME, GAME_EVENT_UTC, CITY, REGION, COUNTRY, GAMER_LTZ_NAME, GAME_EVENT_LTZ, DOW_NAME, TOD_NAME)
VALUES (IP_ADDRESS, GAMER_NAME, GAME_EVENT_NAME, GAME_EVENT_UTC, CITY, REGION, COUNTRY, GAMER_LTZ_NAME, GAME_EVENT_LTZ, DOW_NAME, TOD_NAME);

EXECUTE TASK AGS_GAME_AUDIENCE.RAW.LOAD_LOGS_ENHANCED;

create or replace task AGS_GAME_AUDIENCE.RAW.GET_NEW_FILES
USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
schedule='5 Minutes'
  as
    copy into AGS_GAME_AUDIENCE.RAW.PIPELINE_LOGS
from @AGS_GAME_AUDIENCE.RAW.UNI_KISHORE_PIPELINE
file_format = (format_name=AGS_GAME_AUDIENCE.RAW.FF_JSON_LOGS);

EXECUTE TASK AGS_GAME_AUDIENCE.RAW.GET_NEW_FILES;

TRUNCATE table ENHANCED.LOGS_ENHANCED;
select * from enhanced.logs_enhanced;
select * from AGS_GAME_AUDIENCE.RAW.PIPELINE_LOGS;

--Turning on a task is done with a RESUME command
alter task AGS_GAME_AUDIENCE.RAW.GET_NEW_FILES resume;
alter task AGS_GAME_AUDIENCE.RAW.LOAD_LOGS_ENHANCED resume;

--Keep this code handy for shutting down the tasks each day
alter task AGS_GAME_AUDIENCE.RAW.GET_NEW_FILES suspend;
alter task AGS_GAME_AUDIENCE.RAW.LOAD_LOGS_ENHANCED suspend;

--Step 1 - how many files in the bucket?
list @AGS_GAME_AUDIENCE.RAW.UNI_KISHORE_PIPELINE;

--Step 2 - number of rows in raw table (should be file count x 10)
select count(*) from AGS_GAME_AUDIENCE.RAW.PIPELINE_LOGS;

--Step 3 - number of rows in raw table (should be file count x 10)
select count(*) from AGS_GAME_AUDIENCE.RAW.PL_LOGS;

--Step 4 - number of rows in enhanced table (should be file count x 10 but fewer rows is okay)
select count(*) from AGS_GAME_AUDIENCE.ENHANCED.LOGS_ENHANCED;

use role accountadmin;
grant EXECUTE MANAGED TASK on account to SYSADMIN;

--switch back to sysadmin
use role sysadmin;

truncate table AGS_GAME_AUDIENCE.RAW.PIPELINE_LOGS;
truncate table AGS_GAME_AUDIENCE.ENHANCED.LOGS_ENHANCED;