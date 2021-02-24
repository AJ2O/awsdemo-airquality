terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
}

# Configure Athena
resource "aws_s3_bucket" "data_repository" {
  bucket_prefix = "awsdemo-aqa-data"
  acl           = "private"

  tags = var.tags
}
resource "aws_s3_bucket" "query_execution_results" {
  bucket_prefix = "awsdemo-aqa-results"
  acl           = "private"

  tags = var.tags
}
resource "aws_athena_workgroup" "workgroup" {
  name = "awsdemo-airqualityanalysis"

  tags = var.tags
}
resource "aws_athena_database" "main" {
  name   = "main"
  bucket = aws_s3_bucket.query_execution_results.bucket
}

resource "aws_athena_named_query" "create_table" {
  name      = "createTable"
  workgroup = aws_athena_workgroup.workgroup.id
  database  = aws_athena_database.main.name
  query     = <<EOF
CREATE EXTERNAL TABLE IF NOT EXISTS dailyairquality (
         `statecode` string,
         `countycode` string,
         `sitenum` string,
         `parametercode` string,
         `poc` string,
         `latitude` string,
         `longitude` string,
         `datum` string,
         `parametername` string,
         `sampleduration` string,
         `pollutantstandard` string,
         `datelocal` string,
         `unitsofmeasure` string,
         `eventtype` string,
         `observationcount` string,
         `observationpercent` float,
         `arithmeticmean` string,
         `1stmaxvalue` string,
         `1stmaxhour` string,
         `aqi` string,
         `methodcode` string,
         `methodname` string,
         `localsitename` string,
         `address` string,
         `statename` string,
         `countyname` string,
         `cityname` string,
         `cbsaname` string,
         `dateoflastchange` string 
) 
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
         'escapeChar'='\\', 'separatorChar'=',') LOCATION 's3://${aws_s3_bucket.data_repository.id}/' TBLPROPERTIES ( 'has_encrypted_data'='false', 'skip.header.line.count'='1' ); 
EOF
}
resource "aws_athena_named_query" "test_query" {
  name      = "testQuery"
  workgroup = aws_athena_workgroup.workgroup.id
  database  = aws_athena_database.main.id
  query     = <<EOF
SELECT cityname, statename, arithmeticmean
FROM dailyairquality
WHERE datelocal = '2018-10-09'
        AND arithmeticmean = 
    (SELECT MAX(arithmeticmean)
    FROM dailyairquality
    WHERE datelocal = '2018-10-09');
EOF
  depends_on = [
    aws_s3_bucket.data_repository,
  ]
}