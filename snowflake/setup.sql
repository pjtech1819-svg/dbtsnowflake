-- Set up the defaults
CREATE WAREHOUSE IF NOT EXISTS COMPUTE_WH;
USE WAREHOUSE COMPUTE_WH;

DROP DATABASE IF EXISTS AIRBNB CASCADE;

CREATE DATABASE AIRBNB;

CREATE SCHEMA IF NOT EXISTS AIRBNB.RAW;
CREATE SCHEMA IF NOT EXISTS AIRBNB.DEV;

USE DATABASE AIRBNB;
USE SCHEMA RAW;

-- Create our three tables and import the data from S3
CREATE OR REPLACE TABLE raw_listings
                    (id integer,
                     listing_url string,
                     name string,
                     room_type string,
                     minimum_nights integer,
                     host_id integer,
                     price string,
                     created_at datetime,
                     updated_at datetime);

COPY INTO raw_listings (id,
                        listing_url,
                        name,
                        room_type,
                        minimum_nights,
                        host_id,
                        price,
                        created_at,
                        updated_at)
                   from 's3://dbt-datasets/listings.csv'
                    FILE_FORMAT = (type = 'CSV' skip_header = 1
                    FIELD_OPTIONALLY_ENCLOSED_BY = '"');


CREATE OR REPLACE TABLE raw_reviews
                    (listing_id integer,
                     date datetime,
                     reviewer_name string,
                     comments string,
                     sentiment string);

COPY INTO raw_reviews (listing_id, date, reviewer_name, comments, sentiment)
                   from 's3://dbt-datasets/reviews.csv'
                    FILE_FORMAT = (type = 'CSV' skip_header = 1
                    FIELD_OPTIONALLY_ENCLOSED_BY = '"');


CREATE OR REPLACE TABLE raw_hosts
                    (id integer,
                     name string,
                     is_superhost string,
                     created_at datetime,
                     updated_at datetime);

COPY INTO raw_hosts (id, name, is_superhost, created_at, updated_at)
                   from 's3://dbt-datasets/hosts.csv'
                    FILE_FORMAT = (type = 'CSV' skip_header = 1
                    FIELD_OPTIONALLY_ENCLOSED_BY = '"');

-- Use an admin role
USE ROLE ACCOUNTADMIN;

-- Create the `transform` role
DROP ROLE IF EXISTS TRANSFORM;
CREATE ROLE TRANSFORM;
GRANT ROLE TRANSFORM TO ROLE ACCOUNTADMIN;

-- Create the default warehouse if necessary
GRANT OPERATE ON WAREHOUSE COMPUTE_WH TO ROLE TRANSFORM;

-- Create the `dbt` user and assign to role
DROP USER IF EXISTS dbt;
CREATE USER IF NOT EXISTS dbt
  LOGIN_NAME='dbt'
  TYPE=SERVICE
  RSA_PUBLIC_KEY="MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAsGcvZU2meHtmvYObVopO
HIlE7oovTSqBVZqDGEv9W9jFoECQ0KH16KJXQsyNZ2FREsK4MjparEYX/Ig+fIMc
u/IlviaEawG0eaBPACexAohotFwNY3b72YevNWd863YAd5eQAngq3pP/8Y0y9sAp
qFlLfSKhG/7ajedWfNJMkxBrmrH9evYem4M+jbCkeqi4kQEjTF1PxZQ7ACj50ywc
LUnNStiDTPsB6jiRgtLvnJou9NrBuB0ejN0GJpJZZtzb3YZA1B/7Nr8xAUPlmBGy
9NRVmfI968AJWIOl7leHEvlE0HiR2V0IfQJlr9DXBgtmKGflsqA1NHEUXIRE1wU9
swIDAQAB"
  DEFAULT_ROLE=TRANSFORM
  DEFAULT_WAREHOUSE='COMPUTE_WH'
  DEFAULT_NAMESPACE='AIRBNB.RAW'
  COMMENT='DBT user used for data transformation';

GRANT ROLE TRANSFORM to USER dbt;

-- Set up permissions to role `transform`
GRANT ALL ON WAREHOUSE COMPUTE_WH TO ROLE TRANSFORM;
GRANT ALL ON DATABASE AIRBNB to ROLE TRANSFORM;
GRANT ALL ON ALL SCHEMAS IN DATABASE AIRBNB to ROLE TRANSFORM;
GRANT ALL ON FUTURE SCHEMAS IN DATABASE AIRBNB to ROLE TRANSFORM;
GRANT ALL ON ALL TABLES IN SCHEMA AIRBNB.RAW to ROLE TRANSFORM;
GRANT ALL ON FUTURE TABLES IN SCHEMA AIRBNB.RAW to ROLE TRANSFORM;




