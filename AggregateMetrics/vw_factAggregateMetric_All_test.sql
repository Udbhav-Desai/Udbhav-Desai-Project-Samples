/****** Script for SelectTopNRows command from SSMS  ******/
CREATE OR ALTER VIEW temp.vw_factAggregateMetric_All_test AS 
WITH sum_level_map AS
(
		SELECT 
			sumLevelId,
			STRING_AGG(cast(sumLevel.summary_level as nvarchar(max)),'|') WITHIN GROUP (ORDER BY summary_level_split.ItemIndex) as summary_level_name
		FROM
			(
				SELECT DISTINCT
						fact.summary_level as sumLevelId
				FROM	mart.factAggregateMetric fact
			 ) sum_level_subq

		  CROSS APPLY dbo.SplitStringWithIndex(sumLevelId,'|') summary_level_split
		  LEFT JOIN		mart.dimAggregateMetricSummaryLevel sumLevel
		  ON			sumLevel.summary_level_id = try_cast(summary_level_split.Val as bigint)


		 group by sumLevelId
 )
 ,target_prep as
 (
 select distinct
			
			fact.summary_level,
			fact.target_id, 
			summary_level_split.Val as sum_level_val,
			c.Client_Name,
			tar.target_display_name,
			target_split.ItemIndex
 from		mart.factAggregateMetric fact
 cross apply dbo.SplitStringWithIndex(target_id,'|') target_split
 cross apply dbo.SplitStringWithIndex(summary_level,'|') summary_level_split

 left join	 mart.dimAggregateTarget tar
 on			try_cast(target_split.Val as bigint) = tar.target_id
 and		try_cast(summary_level_split.Val as bigint) = tar.summary_level_id
 and		target_split.ItemIndex = summary_level_split.ItemIndex

 left join	dbo.client c
  on		try_cast(target_split.Val as bigint) = c.Client_ID
 and		try_cast(summary_level_split.Val as bigint) = 1
 and		target_split.ItemIndex = summary_level_split.ItemIndex


),
target_map as
(
select
		summary_level
		,target_id
		,STRING_AGG(
						CAST(CASE WHEN try_cast(sum_level_val as bigint) = 1
								THEN Client_Name
								ELSE target_display_name
							END AS nvarchar(MAX))
						,'|') 
			WITHIN GROUP (ORDER BY ItemIndex) as target_name
		,MAX(ItemIndex)+1 num_Intervals
from	target_prep
GROUP BY 	
			summary_level,
			target_id
)

SELECT 
	fact.[metric_id]
	  ,met.metric_name
	  ,met.metric_display_name
	  ,met.metric_description
      ,fact.[summary_level]
	  ,sum_level_map.summary_level_name
      ,fact.[target_id]
	  ,target_map.target_name
	  ,target_map.num_Intervals
      ,fact.[rpt_date_display]
      ,fact.[value_numerator]
      ,fact.[value_denominator]
      ,fact.[value_numeric]
	  ,value_date_meaning = met.value_date
      ,fact.[value_date]
      ,fact.[value_text]
      ,fact.[meta_data]
      ,fact.[percentile]
      ,fact.[last_update_dt]
	  
  FROM [mart].[factAggregateMetric] fact

  JOIN mart.dimAggregateMetric met
  ON	fact.metric_id = met.metric_id

  JOIN	sum_level_map
  ON	sum_level_map.sumLevelId = fact.summary_level

  LEFT JOIN	target_map
  ON		target_map.summary_level = fact.summary_level
  AND		target_map.target_id = fact.target_id

  --WHERE 
  --met.metric_id = 1
  --and target_id = '-1'