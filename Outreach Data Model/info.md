# Outreach Data Model & Engagement Projects
## Background:

As a part of a company-wide goal to shift our narrative on engagement, 
I worked on a project to consolidate engagement data into a comprehensive 
and scalable data model, as well as reporting tools to aid internal and external 
conversations for the engagement transformation. Reporting tools for this 
initiative would need to provide historical and future context on how well 
different tactics work to engage members into 2 main categories of services. For historical 
context, we needed to set up the ability generate on-the-fly benchmarks that client, 
sales and marketing teams could use to establish different marketing strategies with clients.

 

## Outreach Data Model:

Engagement tactic data live in a multitude of data sources. I first worked 
with Engagement Directors, Client team managers, Marketing Directors and 
Call Center Managers to establish a repository of all the different ways we 
do outreach for our client members. After generating a repository of tactic 
types, I worked with SMEs for each tactic type to better understand the data 
that’s been tracked. Given the large repository of tactic types and variation in 
data tracking, I established a data quality evaluation methodology to prioritize which tactics 
could be added to the outreach data model. For tactics with the lowest scores, I worked the 
engaged SMEs and development teams to establish better workflows to improve reporting and benchmarking feasibility.

 

## Outreach Schema (Key Tables Only)

* Engagement Tactic Dimension Table – metadata and triggers for each engagement tactic
* Outreach Events Fact Table – 1 row represents each time an individual was outreached for a different tactic type
* Outreach Conversions Fact Table – for each outreach event, what engagement activity could be associated (either time-based or direct association)
* Participant Snapshot Aggregate Table – how many times a participant was outreached in a given year, along with conversion metrics
* Outreach Snapshot Aggregate Table – generates benchmarks using the participant snapshot for a combination of different data dimensions used to information marketing strategies on the Engagement Index dashboard
* Report Card Snapshot Aggregate Table – generate client-level scores on a rolling 8-quarter basis to demonstrate the strength of engagement efforts for a particular client and how that client ranks against similar clients in their industry and size. Used in a client-facing report card
 

## Reporting Tools

* Engagement Index – an interactive dashboard where users can select different engagement tactics and visualize the historical outcomes from a mix of tactics for 2 main KPI. Users can build their own segment analysis by dynamically grouping and filtering down subpopulations tactic tdata
* Report Card – a client-facing report that summarizes client engagement and conversion. The report card provides overtime trends specific to the client, benchmarks against like clients, demographic details, data gaps, and effectiveness of marketing for different tactics.
