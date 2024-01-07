### Tools
Tableau, MS SQL Server

### Background: 
The Navigation department at Alight Solutions used to report out of SSRS. For reporting on Net Promoter, there were 3 different SSRS reports, each with long run times and a history of user complaints regarding performance and ability to interactively slice-and-dice to generate insights. The SSRS reports were also pretty basic, tabular reports, which did not make it easy to visualize data trends. The Navigation department prioritized an initiative to migrate SSRS content Tableau for a better user experience and generate insights more quickly. In this effort, I worked with operational and product leads to define requirements, design a new flow of information, build data structures in SQL to support a dashboard and constructed a visually stunning dashboard.

On the dashboard, you can find an overview page, trend by employer (Alight’s clients are employers), Agent (Alight employees who work with employer members on healthcare guidance solutions) and a details table.

This was also one of the first dashboards in a SSRS > Tableau migration. I built this to demonstrate Tableau capabilities, illustrate our direction with dashboarding and training my direct reports on design/Tableau functionality. I also learned Tableau in under 1 month and unleashed some advanced features within the first release.

 

### Overview Page

- Trend total NPS by any date granularity you select at the top (Day, Week, Month, Quarter, Year)
- Breakout of NPS by Solution Category (understand the performance by service type)
- Breakout of NPS by individual NPS rating
- Trends for closed solution volume, surveys sent (plus toggle feature to display survey not sent reason breakouts), ratings received and response rate
- Interactivity – clicking on a visual like NPS overtime will cross-filter on breakouts by score and solution type. Users can also click on groupings to drill into details
 

### NPS By Employer

- See NPS breakouts by employer, SLA enterprise (client service lines), and employer Pods (how employers are grouped internally)
- Isolate employers based on volume of survey responses. This could be a good way to see which employers have the best experiences if we isolate high volume accounts.
Drill into details by selecting any category
 

### NPS By Agent

- For internal performance tracking, users can visualize NPS by Manager, lead and agent. NPS can also be broken out by an agent’s role on a solution (i.e if they triaged, researched or served as primary communicator)
- Again, drill into details by clicking on any member, lead or manager
 

### Survey Details

- Displays key information about a survey and allows a user to jump into the solution directly to investigate further
- For initial performance throttling, 25 records are loaded at a time with an option to page through results. Users can choose X number of records to load at a time or even all records.
 

### Outcomes/Reactions

- Reports that averaged >100 seconds to retrieve results in SSRS are now available in seconds in Tableau. Data is loaded every morning via extracts, and the dashboard is designed tactfully to balance performance with user needs.
- Over 50 daily users within the first 3 weeks of release.
- “This is a gamechanger for me. I go into this every day and I can learn some much more than I could with my previous, static reports” – Senior Manager in Operations
- “Could we have Udbhav and his team build dashboards for us, too?” – manager in a separate division at Alight
- “I see that we are being really mindful and strategic with our Tableau migration. Really impressed by the results, thank you!!” – VP
