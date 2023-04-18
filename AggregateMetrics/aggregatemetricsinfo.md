# Aggregate Metrics
## Background
I was looking for a way to create a KPI model in the SQL server that stores aggregated metrics overtime in a number of different grouping levels.
This data model needed to be flexible, low-maintenance and scalable. 

## Vertical Elements
* Metric - What KPI are we tracking? (i.e. survey response rate, utilization rate, etc.)
* Summary Level - What slices of the KPI are we tracking? (i.e. client, industry, product category, etc.)
* Target - What individual elements of a slice are we tracking? (i.e. specific client)

## Horizontal Elements
* Reporting Date - How do we track this KPI overtime?

## Values To Store Per Metric Target
* Numerator
* Denominator (optional)
* Rate (numerator/denominator)
* Value Metadata (extra pieces of information to store about metric)


## Benefits of Design Structure
* **Modularized** - mechanisms to add/remove individual metrics or summary levels and targets without disrupting entire data model. Each metric gets its own stored procedure.
* **Metadata Capture** - Built to allow developers to store definitions for the metric, date, numerator, denominator, and rate.
* **Centralized Automation** - One master stored procedure and pipeline to process all metrics.
* **Customizable Capture frequency** - can choose to process metrics daily (default), weekly, monthly, quarterly, yearly at the metric level.
* **Built for Auditing and Historical Tracking** -
  * Central stored procedure tracks metadata about each stored procedure that runs (when it runs, how many rows added, updated, deleted)
  * Historical table stores all older data that can be pulled in for audits

## Key Features
* PowerApp to store metric metadata to a key dimension table for each metric
* Simple, easy to extend scehma (see ER diagram)
* Stored Procedure Template for developers
* 1 master stored procedure to capture data for all metrics in data model and logic historic data
* 1 pipeline in Azure Data Factory to automate data capture
* 1 SQL view that join dimension tables to fact tables for easy reports
* 1 KPI Explorer Dashboard to easily slice and dice on the data
