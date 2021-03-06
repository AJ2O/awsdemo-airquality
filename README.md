# AWS Demo: Air Quality Analysis
This was a freestyle project to choose any combination of AWS services to solve a problem.

# The Situation
You work for a US-based, non-profit organization that promotes better environmental conditions in communities most in need.

Currently, your organization is preparing a campaign around the awareness of Ozone (O3) as a pollutant.

You have been asked to identify the top regions in the US with the highest average Ozone levels for use in a regionally-targeted social media awareness campaign.

# Requirements

#### 1. Identify an open-source data repository for air quality readings.

#### 2. Set up a way to query that data via AWS services and tools.

#### 3. What city had the highest average ozone reading on October 9, 2018?

# My Solution
Included in this repository is a [Terraform script](main.tf) that will automatically set up the solution resources in AWS. If you don't already, I highly recommend using Terraform as an [Infrastructure as Code](https://www.hashicorp.com/resources/what-is-infrastructure-as-code) tool to automate the setup of your cloud environments. It's compatible with a hundreds of cloud providers, including Microsoft Azure, Google Cloud Platform, VMware vSphere and Kubernetes. It can be downloaded from [HashiCorp's official website](https://www.terraform.io/downloads.html).

### Requirement 1.
After searching online, I found that the **United States Environmental Protection Agency (EPA)** has [public air quality data](https://www.epa.gov/outdoor-air-quality-data) available across the US at the state, county, and city levels. It can be accessed either [live on the website](https://www.epa.gov/outdoor-air-quality-data/download-daily-data), [via API](https://aqs.epa.gov/aqsweb/documents/data_api.html), or by [downloading CSV files](https://aqs.epa.gov/aqsweb/airdata/download_files.html).

I selected to download the [Daily Summary Data CSV for Ozone in 2018](https://aqs.epa.gov/aqsweb/airdata/download_files.html#Daily) for two reasons:
- **1.** The API has a daily limit on the amount of times it can be called, which could be problematic if we have to query it many times a day. If we have a copy of the data locally, we can run as many queries as we want against it.
- **2.** We at least need daily data for 2018 to answer [requirement 3](#3-what-city-had-the-highest-average-ozone-reading-on-october-9-2018).

### Requirement 2.
For AWS services, I chose [Amazon S3](https://aws.amazon.com/s3/) to store the CSV, and [Amazon Athena](https://aws.amazon.com/athena/) to query it.

Athena has native support for running SQL queries against CSV files in S3, and since the CSV file was only 122 MB, it would be very cheap to query the data. In fact, we could run [1500+ Athena queries per month for less than a dollar](https://calculator.aws/#/estimate?id=f79f51a96264e7745f865a29e144268afa49ade7).

The file is also small enough to stay within [S3 Free Tier](https://calculator.aws/#/estimate?id=17b2dff3fa28f1c5ece27caf7ccda3855e4cf4d2), so that's why I chose S3 to store the data.

Both services are also very easy to set up, manage, and run. All we need to do is upload the data to S3, and run simple SQL queries.

#### Alternatives
Alternatives that could be used include database services such as [RDS](https://aws.amazon.com/rds/) and [DynamoDB](https://aws.amazon.com/dynamodb/). The problem with those solutions however, is that we need to configure the databases before we can run queries. This includes creating the tables, schemas, database instance (in the case of RDS), and other service-specific settings. We would also need to then populate the databases with the air quality data. 

We already have a full, structured data set in the CSV files provided by the EPA,  so we shouldn't need to burden ourselves with unnecessary work. We can just download them, drop them into S3, and start running queries immediately with Athena.

### Requirement 3.
I ran the query in the AWS CLI, and the answer was Kelso, California at an average ozone reading of `0.060353` on October 9, 2018. If you want to try out the query, remember to replace the workgroup with your own: 
```
$ aws athena start-query-execution --query-string \
> "SELECT cityname, statename, arithmeticmean \
> FROM dailyairquality \
> WHERE datelocal = '2018-10-09' \
>         AND arithmeticmean = \
>     (SELECT MAX(arithmeticmean) \
>     FROM dailyairquality \
>     WHERE datelocal = '2018-10-09');" \
> --work-group awsdemo-airqualityanalysis
{
    "QueryExecutionId": "8dccc3a4-1b41-4aaf-a625-ecdc186639af"
}

$ aws athena get-query-results --query-execution-id "8dccc3a4-1b41-4aaf-a625-ecdc186639af" | jq .ResultSet.Rows
[
  {
    "Data": [
      {
        "VarCharValue": "cityname"
      },
      {
        "VarCharValue": "statename"
      },
      {
        "VarCharValue": "arithmeticmean"
      }
    ]
  },
  {
    "Data": [
      {
        "VarCharValue": "Kelso"
      },
      {
        "VarCharValue": "California"
      },
      {
        "VarCharValue": "0.060353"
      }
    ]
  }
]
```

# Try out the Solution!
The [Terraform](main.tf) script will set up the S3 buckets, Athena database, and Athena queries in AWS. Before you test out the solution, make sure of a couple of things:
- Download the [Daily Summary Data for Ozone for 2018](https://aqs.epa.gov/aqsweb/airdata/download_files.html#Daily)
- Upload the CSV file to the S3 bucket prefixed by `awsdemo-aqa-data` which would have been created by Terraform
- If you are running the Athena queries from the AWS CLI, make sure to include the argument `--work-group awsdemo-airqualityanalysis`
  - This workgroup would have been made by Terraform too
- There are two saved Athena queries created: `createTable` and `testQuery`
  - Run `createTable` first to initialize the table
  - Run `testQuery` after to check [requirement 3](#requirement-3)

