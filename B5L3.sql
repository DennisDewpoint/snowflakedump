--what time zone is your account(and/or session) currently set to? Is it -0700?
select current_timestamp();

--worksheets are sometimes called sessions -- we'll be changing the worksheet time zone
alter session set timezone = 'UTC';
select current_timestamp();

--how did the time differ after changing the time zone for the worksheet?
alter session set timezone = 'Africa/Nairobi';
select current_timestamp();

alter session set timezone = 'Pacific/Funafuti';
select current_timestamp();

alter session set timezone = 'Asia/Shanghai';
select current_timestamp();

--show the account parameter called timezone
show parameters like 'timezone';

list @uni_kishore;

select $1
from @uni_kishore/updated_feed/DNGW_updated_feed_0_0_0.json
(file_format => ff_json_logs);

copy into ags_game_audience.raw.GAME_LOGS
from @uni_kishore/updated_feed/DNGW_updated_feed_0_0_0.json
file_format = (format_name=FF_JSON_LOGS);

select * from GAME_LOGS;
select * from LOGS;

truncate table ags_game_audience.raw.GAME_LOGS;

select $1:agent::text, $1:ip_address::text
from game_logs;

delete from ags_game_audience.raw.GAME_LOGS
where RAW_LOG:agent::text is null;

select * from game_logs
where RAW_LOG:agent::text is null;

select * from logs
WHERE USER_LOGIN ilike '%prajina%';B