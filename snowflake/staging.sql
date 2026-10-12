create database DEMO;

create schema DEMO.DEMO_SCHEMA;

CREATE OR REPLACE STAGE DEMO.DEMO_SCHEMA.weather_stage
url='s3://snowflake-workshop-lab/weather-nyc'
	FILE_FORMAT= (TYPE='json');
LIST @DEMO.DEMO_SCHEMA.weather_stage;

---Analyse data inside the json files---
create or replace table DEMO.DEMO_SCHEMA.weathertable ( data variant);

copy into DEMO.DEMO_SCHEMA.weathertable  
from @DEMO.DEMO_SCHEMA.weather_stage;

---extract the columns from the json data in the snowflake table (with variant data type)-----
SELECT
	data:city:findname,
	data:city:coord:lat,
	data:city:coord:lon,
	data:clouds:all,
	data:main:humidity,
	data:main:pressure,
	data:main:temp,
	data:time,
	data:weather[0]:main
	FROM DEMO.DEMO_SCHEMA.WEATHERTABLE;

----copying the data directly from stage to snowflake table-------
CREATE OR REPLACE TABLE DEMO.DEMO_SCHEMA.WEATHER (
	CITYNAME STRING,
	LAT FLOAT,
	LON FLOAT,
	CLOUDS INTEGER,
	HUMIDITY INTEGER,
	PRESSURE FLOAT,
	TEMP FLOAT,
	TIME TIMESTAMP,
	WEATHER STRING
	);

COPY INTO DEMO.DEMO_SCHEMA.WEATHER
	FROM
	(
	select
	t.$1:city:findname,
	t.$1:city:coord:lat,
	t.$1:city:coord:lon,
	t.$1:clouds:all,
	t.$1:main:humidity,
	t.$1:main:pressure,
	t.$1:main:temp,
	t.$1:time,
	t.$1:weather[0]:main
	FROM @DEMO.DEMO_SCHEMA.weather_stage t);

    select * from DEMO.DEMO_SCHEMA.WEATHER;

    CREATE OR REPLACE STAGE DEMO.DEMO_SCHEMA.BIKE_STAGE;
----with put command we can upload the data from local machine to snowflake stage using the snowsql in cmd by using below commands and snowsql used to upload files from your local drive to a Snowflake stage---
    --use database DEMO;--
    --use schema DEMO_SCHEMA;---
    --put 'file://C:/Users/Admin/Downloads/2023-citibike-tripdata/2023-citibike-tripdata/*/*.csv' @BIKE_STAGE;----
    

    SELECT
	t.$1,
	t.$2,
	t.$3,
	t.$4,
	t.$5,
	t.$6,
	t.$7,
	t.$8,
	t.$9,
	t.$10,
	t.$11,
	t.$12,
	t.$13,
	t.$14
	FROM @DEMO.DEMO_SCHEMA.BIKE_STAGE t;

    -- Command to create the BIKE table

		CREATE OR REPLACE TABLE DEMO.DEMO_SCHEMA.BIKE (

		RIDE_ID STRING,
		RIDEABLE_TYPE STRING,
		STARTED_AT STRING,
		ENDED_AT STRING,
		START_STATION_NAME STRING,
		START_STATIO_ID STRING,
		END_STATION_NAME STRING,
		END_STATION_ID STRING,
		START_LAT STRING,
		START_LNG STRING,
		END_LAT STRING,
		END_LNG STRING,
		MEMBER_CSUAL STRING);
    
    COPY INTO DEMO.DEMO_SCHEMA.BIKE
			FROM
			(
			SELECT
			t.$1,
			t.$2,
			t.$3,
			t.$4,
			t.$5,
			t.$6,
			t.$7,
			t.$8,
			t.$9,
			t.$10,
			t.$11,
			t.$12,
			t.$13
			FROM
			@DEMO.DEMO_SCHEMA.BIKE_STAGE t);
select * from DEMO.DEMO_SCHEMA.BIKE limit 10;

--- Command used to create a scheduled task:


		CREATE TASK DEMO.DEMO_SCHEMA.WEATHERTASK
		WAREHOUSE =COMPUTE_WH
		SCHEDULE='USING CRON 0 0 * * * UTC'
		AS 

		COPY INTO DEMO.DEMO_SCHEMA.WEATHER
			FROM
			(
			select
			t.$1:city:findname,
			t.$1:city:coord:lat,
			t.$1:city:coord:lon,
			t.$1:clouds:all,
			t.$1:main:humidity,
			t.$1:main:pressure,
			t.$1:main:temp,
			t.$1:time,
			t.$1:weather[0]:main
			FROM @DEMO.DEMO_SCHEMA.weather_stage t);

--*** Snowflake Tasks - Creation of a child task and DAG of tasks ***
--- Command used to create the BIKETASK:


CREATE TASK DEMO.DEMO_SCHEMA.BIKETASK
WAREHOUSE =COMPUTE_WH
AFTER DEMO.DEMO_SCHEMA.WEATHERTASK
	AS
	COPY INTO DEMO.DEMO_SCHEMA.BIKE
				FROM
				(
				SELECT
				t.$1,
				t.$2,
				t.$3,
				t.$4,
				t.$5,
				t.$6,
				t.$7,
				t.$8,
				t.$9,
				t.$10,
				t.$11,
				t.$12,
				t.$13
				FROM
				@DEMO.DEMO_SCHEMA.BIKE_STAGE t);

show tasks in DEMO.DEMO_SCHEMA;

---*** Snowflake Tasks - Management ***

---- Command used to resume the suspended Snowflake tasks:

	ALTER TASK DEMO.DEMO_SCHEMA.BIKETASK RESUME;
	ALTER TASK DEMO.DEMO_SCHEMA.WEATHERTASK RESUME;


---- Command used to show the tasks in your Snowflake account:

	SHOW TASKS;


---- Command used to manually trigger a task:

	EXECUTE TASK DEMO.DEMO_SCHEMA.WEATHERTASK;

---- Command used to see what tasks have been run and which ones are scheduled:

		SELECT *
		  FROM TABLE(DEMO.INFORMATION_SCHEMA.TASK_HISTORY())
		  ORDER BY SCHEDULED_TIME;

