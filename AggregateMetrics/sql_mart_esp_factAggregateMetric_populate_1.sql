			SET ANSI_NULLS ON
			GO

			SET QUOTED_IDENTIFIER ON
			GO

	
	CREATE OR ALTER PROCEDURE mart.esp_factAggregateMetric_populate_1		AS
	BEGIN		
					SET NOCOUNT ON;

						SELECT

									[metric_id]				=	1

									,[summary_level]			= 			
																	CASE 													
																					CAST (GROUPING_ID(client_id) AS CHAR(1))
																				+	CAST (GROUPING_ID(Case_Rec_Type) AS CHAR(1))

																		WHEN '11' THEN '-1'			-- CM-Wide
																		WHEN '01' THEN '1'			-- Client
																		WHEN '10' THEN '6'			-- Case Record Type
																		WHEN '00' THEN '1|6'	    -- Client|Case Record Type
																	END

									,[target_id]				=	
																	CASE

																					CAST (GROUPING_ID(client_id) AS CHAR(1))
																				+	CAST (GROUPING_ID(Case_Rec_Type) AS CHAR(1))

																		WHEN '11' THEN '-1'																								-- CM-Wide
																		WHEN '01' THEN ISNULL(CAST(client_id AS NVARCHAR(250)),'-2')																-- Client
																		WHEN '10' THEN CAST(MAX(tar.target_id) AS NVARCHAR(250))																-- Case Record Type
																		WHEN '00' THEN CAST(MAX(ISNULL(client_id,-2)) AS VARCHAR(250))+'|'+CAST(MAX(tar.target_id) AS VARCHAR(250))		    -- Client|Case Record Type
																	END

									,[rpt_date_display]		=		FORMAT(CAST(COALESCE(c.adjusted_open_date,c.created_Date) AS DATE), 'MM/dd/yy')

									,[value_numerator]		=		COUNT(DISTINCT c.Case_ID)

									,[value_denominator]	=		NULL
				
									,[value_numeric]		=		COUNT(DISTINCT c.Case_ID)


									,[value_date]			=		CAST(COALESCE(c.adjusted_open_date,c.created_Date)  AS DATE)

									,[value_text]			=		FORMAT(COUNT(DISTINCT c.Case_ID), '#,###')

									,[meta_data]			=		NULL

									,[percentile]			=		NULL

									,[last_update_dt]       =		GETDATE()

									
					FROM 			[dbo].[case] c
	
						JOIN		[dbo].[service_request] sr
						ON			sr.Service_Request_ID	= c.Service_Request_ID

						JOIN		[dbo].[person] p
						ON			p.Person_ID = c.Patient_ID

						LEFT JOIN	[mart].[dimAggregateTarget] tar
						ON			tar.target_db_name = ISNULL(c.Case_Rec_Type,'Unknown')
						AND			tar.summary_level_id = 6  -- Case Record Type


					WHERE		
							c.Case_Name NOT IN ('YOUR HOW-TO GUIDE: START HERE!')

					GROUP BY
					GROUPING SETS (CUBE (
								p.client_id
								,Case_Rec_Type
			
							))
						, CAST(COALESCE(c.adjusted_open_date,c.created_Date) AS DATE);


END


