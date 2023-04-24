# About the Challenge
This was an entry to a Maven Analytics Challenge family leave data - [Family Leave Challenge](https://www.mavenanalytics.io/challenges/maven-family-leave-challenge/2). The task was to take a crowdsourced dataset from Fairygodboss and create visuals to support an online business article.
                                                                                            
# Data Preparation
* Replace N/A values in potentially numeric columns with blank > transform from text to decimal (applicable to unpaid maternity leave, paid paternity leave, unpaid paternity leave)
* Now, what to do about the blank values in the numeric columns? The blank could either mean unknown or no leave offering. I assume that the blanks mean unknown for this analysis.
* Collins Aerospace: this company was represented twice in the dataset with 2 very conflicting data points on maternity leave (12 weeks paid and 0 weeks unpaid vs 4 weeks paid and 12 weeks unpaid). After researching the company website and comments on Indeed and Glassdoor, I couldn't conclude which was the correct data point. For that reason, I chose to exclude Collins Aerospace from this analysis. 
* Industry: 
  * First, there were 3 companies with a N/A industry. I researched those 3 companies and assigned an industry value that would best match one of the other non-N/A values. 
  * Second, there were 136 distinct values. Noticed many of the industries followed the format Higher Level Grouping: Lower Level Grouping, so I created 2 columns: Industry Category and Industry Subcategory. This left me with 42 unique industry category values and 97 industry subcategory values (~21% of companies in the dataset do not have a subcategory, so they have NULL values in this new field so I replaced those with 'Unknown'). 
  * Next, I would want to further consolidate the Industry Category field into Sector values to have larger groups and fewer values to compare - some of the Industry Categories only have 1 company in our dataset. 
* Sector Mapping: I looked at the provided industry list against standards such as NAICS, SIC, and GICS, but this industry list did not seem to have a clean 1:1 mapping to any of those accepted codes. Rather than mapping each Industry Category to a sector, I copied the list of unique values into ChatGPT and asked the tool "Given the list of industries below, create a mapping table of industry to sector". ChatGPT's initial effort was okay, but I was not happy with some of the mappings such as Legal Services to Industrials. So, I asked ChatGPT to re-do this mapping, but this time I asked it to use the GAICS definition of sectors. This time was much better, and left Categories like Legal Services as Not Applicable. I used ChatGPT's second iteration and manually mapped some of the remaining Not Applicable industries into higher level groupings for the purposes of this analysis (i.e Law Firm and Legal Services into Legal).
# Data Analysis
Questions I was interested in answering:
* What are some central tendency statistics for the 4 main variables?
* What are the fill rates for the 4 main variables?
* How do the medians of the paid benefits compare to that of countries like Canada or within the EU?
* Which sectors offer the best benefits to families?
* What is the distribution of paid benefits? How often do companies provide no parental leave?
* What companies excel at providing maternity and paternity paid leave?
* Are there any unusual findings? Like, are any companies providing a longer paid paternity leave than a paid maternity leave?
# Tools Used
* Power BI and Power Query - data prep and analysis
* Canva - visuals
* ChatGPT - Industry to Sector Mapping
* Pew Research Center - benchmarks
