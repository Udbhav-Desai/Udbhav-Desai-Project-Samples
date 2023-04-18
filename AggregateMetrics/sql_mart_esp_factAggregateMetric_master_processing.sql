			SET ANSI_NULLS ON
			GO

			SET QUOTED_IDENTIFIER ON
			GO

	/**
	NAME:		mart.esp_factAggregateMetric_master_processing	
	AUTHOR:		Udbhav Desai
	DATE:		08-16-2021
	PURPOSE:	Update all metrics for the Aggregate Metrics Data Model. Steps as follows:
				1.	Find all metrics that need to run now based on capture frequency and check for existing stored procedure
				2.	Loop through all runnable stored procedures by 1 metric at a time.
				3.	Loop first executes a metric's stored procedure and saves data to a temp table.
				4.	Temp table MERGED with mart.factAggregateMetric
				5.	mart.factAggregateMetric then MERGED with mart.factAggregateMetricHistoric to capture changes
				6.  Successes and failures logged to mart.factAggregateMetricExecutionLog - includes counts of inserts, updates and deletes. 
	**/



	CREATE OR ALTER PROCEDURE mart.esp_factAggregateMetric_master_processing		
	AS
	BEGIN		
	
	SET NOCOUNT ON;



		/***
		=============================================================================
		
		
		FIND EXECUTABLE STORED PROCEDURES.


		=============================================================================
		***/
			DECLARE @procRun TABLE
				(
					metric_id	BIGINT
					,proc_name	VARCHAR(255)
					,run_flag	INT
					,row_num	INT
				)

			INSERT @procRun
					SELECT DISTINCT
							metric_id
							,proc_name
							--,procs.proc_nm
							,run_flag =	case
												-- always run the daily metrics
											when m.capture_frequency_id = 1 then 1

												-- run if never ran or at least 1 week has passed for weekly metrics						
											when m.capture_frequency_id = 2 and (DATEDIFF(WEEK,last_successful_load_dt,getdate())>=1 or last_successful_load_dt is null) then 1	
											
												-- run if never ran or at least 1 month has passed for monthly metrics
											when m.capture_frequency_id = 3 and (DATEDIFF(MONTH,last_successful_load_dt,getdate())>=1 or last_successful_load_dt is null) then 1	
											
												-- run if never ran or at least 1 quarter has passed for quarterly metrics
											when m.capture_frequency_id = 4 and (DATEDIFF(QUARTER,last_successful_load_dt,getdate())>=1 or last_successful_load_dt is null) then 1	
											
												-- run if never ran or at least 1 year has passed for yearly metrics
											when m.capture_frequency_id = 5 and (DATEDIFF(YEAR,last_successful_load_dt,getdate())>=1 or last_successful_load_dt is null) then 1	
											
											else 0
										end
							,row_num = ROW_NUMBER() OVER (ORDER BY METRIC_ID)
					FROM	mart.dimAggregateMetric m

						--check if a stored proc exists with that name
						JOIN
							(
									SELECT	
										s.name	as sch_nm
										,p.name as proc_nm

									  FROM [sys].[procedures] p
									  join sys.schemas s
									  on	s.schema_id = p.schema_id
									  where
									  s.name = 'mart'
							) procs
							ON	
										procs.sch_nm = SUBSTRING(proc_name,1,CHARINDEX('.',proc_name)-1)					--	 schema name
								AND		procs.proc_nm = SUBSTRING(proc_name,CHARINDEX('.',proc_name)+1,LEN(proc_name))		--	 procedure name
					WHERE
							m.capture_frequency_id between 1 and 5 -- Day,Week,Month,Quarter,Year

			--SELECT * FROM @procRun


			DELETE FROM @procRun 
				WHERE run_flag = 0


		/***
		=============================================================================
		
		
		START MAIN LOOP TO EXECUTE ALL PROCEDURES


		=============================================================================
		***/

			-- Loop variables
			DECLARE @ix				INT				= 0;									--loop variable
			DECLARE	@n				INT				= (SELECT MAX(row_num) FROM @procRun);	--number of metrics to process
			DECLARE @runningProc	NVARCHAR(MAX)	= N'';									--stored running stored procedure
			DECLARE @sql			NVARCHAR(MAX)	= N'';									--store sql query to execute with spexecutesql
			DECLARE	@metricID		BIGINT			;										--current metric id
			DECLARE @result			INT;													--spexecute result store

		WHILE @ix <= @n
			BEGIN
			
			--Set variables for the current metric
			
			SET @ix				=	(SELECT MIN(row_num) FROM @procRun);
			SET @runningProc	=	(SELECT 
										MAX(proc_name)
									FROM @procRun
										WHERE row_num = @ix);
			SET @metricID		=	(SELECT 
										MAX(metric_id)
									FROM @procRun
										WHERE row_num = @ix);
								
			SET @sql =  @sql + 'exec ' + @runningProc + '';


			/***
			=============================================================================
		
			ALL TABLE UPDATES IN BEGIN TRY..CATCH CONSTRUCT

			=============================================================================
			***/

			BEGIN TRY
								--	Per-transcation variables
								DECLARE @beginDTTM datetime = GETDATE();
								DECLARE @endDTTM datetime; -- set once the batch ends.
								DECLARE @invalidDTTM datetime = CONVERT(DATETIME, '9999-12-31T23:59:59.997', 126);  -- don't change!

								DECLARE @insertedCount INT;
								DECLARE @updatedCount INT;
								DECLARE @deletedCount INT;
								DECLARE @mergeResultsTable TABLE (MergeAction VARCHAR(20));
								DECLARE @lastUpdateDT DATETIME;


								/***
								=============================================================================
		
									EXECUTE METRIC'S STORED PROCEDURE AND LOAD DATA INTO A TEMP TABLE

									Temp table's definitions must match mart.factAggregateMetric 
										and each SP must return data per those specs.

								=============================================================================
								***/

							DROP TABLE IF EXISTS #PREP_DATA;

								CREATE TABLE #PREP_DATA
								(
									[metric_id] [bigint] NOT NULL,
									[summary_level] [nvarchar](100) NOT NULL,
									[target_id] [nvarchar](250) NOT NULL,
									[rpt_date_display] [nvarchar](500) NOT NULL,
									[value_numerator] [bigint] NOT NULL,
									[value_denominator] [bigint] NULL,
									[value_numeric] [numeric](18, 10) NOT NULL,
									[value_date] [datetime] NOT NULL,
									[value_text] [nvarchar](max) NULL,
									[meta_data] [nvarchar](max) NULL,
									[percentile] [float] NULL,
									[last_update_dt] [datetime] NOT NULL
								)
							INSERT INTO #PREP_DATA
							EXEC sp_executesql @sql, N'@result int output', @result output;


								/***
								=============================================================================
		
								MERGE temp table WITH mart.factAggregateMetric

								=============================================================================
								***/

								BEGIN TRANSACTION

									MERGE		mart.factAggregateMetric as tgt
										USING	#prep_data as src
										ON				tgt.metric_id		= src.metric_id
										AND				tgt.summary_level	= src.summary_level
										AND				tgt.target_id		= src.target_id
										AND				tgt.value_date		= src.value_date

										--Insert new
									WHEN NOT MATCHED BY TARGET
										THEN INSERT 
											(
												[metric_id]
											   ,[summary_level]
											   ,[target_id]
											   ,[rpt_date_display]
											   ,[value_numerator]
											   ,[value_denominator]
											   ,[value_numeric]
											   ,[value_date]
											   ,[value_text]
											   ,[meta_data]
											   ,[percentile]
											)
										VALUES
											(
												src.[metric_id]
											   ,src.[summary_level]
											   ,src.[target_id]
											   ,src.[rpt_date_display]
											   ,src.[value_numerator]
											   ,src.[value_denominator]
											   ,src.[value_numeric]
											   ,src.[value_date]
											   ,src.[value_text]
											   ,src.[meta_data]
											   ,src.[percentile]
											)

											--update unmatched
										WHEN MATCHED AND 
										(
												tgt.hash_id		!=	hashbytes
																			(
																				'SHA2_512'
																				,CONCAT_WS(
																							'|'
																							,src.[metric_id] 
																							,src.[summary_level] 
																							,src.[target_id] 
																							,src.[rpt_date_display] 
																							,src.[value_numerator] 
																							,src.[value_denominator] 
																							,src.[value_numeric] 
																							,src.[value_date] 
																							,src.[value_text] 
																							,src.[meta_data] 
																							,src.[percentile] 
																						)
																			)
										)
										THEN UPDATE
										SET
							
											   tgt.[rpt_date_display]			=	src.[rpt_date_display]
											   ,tgt.[value_numerator]			=	src.[value_numerator]
											   ,tgt.[value_denominator]			=	src.[value_denominator]
											   ,tgt.[value_numeric]				=	src.[value_numeric]
											   ,tgt.[value_text]				=	src.[value_text]
											   ,tgt.[meta_data]					=	src.[meta_data]
											   ,tgt.[percentile]				=	src.[percentile]

									WHEN NOT MATCHED BY SOURCE AND (tgt.METRIC_ID = @metricId)
										THEN DELETE

									OUTPUT $action into @mergeResultsTable;
								;

								-- set row counts
								SELECT
										@insertedCount		=	SUM(CASE WHEN m.[MergeAction]='INSERT' THEN 1 ELSE 0 END)
										,@updatedCount		=	SUM(CASE WHEN m.[MergeAction]='UPDATE' THEN 1 ELSE 0 END)
										,@deletedCount		=	SUM(CASE WHEN m.[MergeAction]='DELETE' THEN 1 ELSE 0 END)
								FROM	@mergeResultsTable m

								--set last update dt
								SELECT
										@lastUpdateDT = max(last_update_dt)
								FROM	mart.factAggregateMetric
								WHERE	metric_id = @metricID

								UPDATE mart.dimAggregateMetric
									SET	last_successful_load_dt = @lastUpdateDT
									WHERE metric_id = @metricID


								/***
								=============================================================================
		
								MERGE factAggregateMetrics WITH mart.factAggregateMetricHistoric

								=============================================================================
								***/

									MERGE		
												mart.factAggregateMetricHistoric as tgt
										USING	mart.factAggregateMetric as src
										ON						tgt.metric_id		= src.metric_id
												AND				tgt.summary_level	= src.summary_level
												AND				tgt.target_id		= src.target_id
												AND				tgt.value_date		= src.value_date

										-- add new rows to history
									WHEN NOT MATCHED BY TARGET
										THEN INSERT 
											(
												[metric_id]
											   ,[summary_level]
											   ,[target_id]
											   ,[rpt_date_display]
											   ,[value_numerator]
											   ,[value_denominator]
											   ,[value_numeric]
											   ,[value_date]
											   ,[value_text]
											   ,[meta_data]
											   ,[percentile]
											   ,[valid_dt]
											   ,[invalid_dt]
											)
										VALUES
											(
												src.[metric_id]
											   ,src.[summary_level]
											   ,src.[target_id]
											   ,src.[rpt_date_display]
											   ,src.[value_numerator]
											   ,src.[value_denominator]
											   ,src.[value_numeric]
											   ,src.[value_date]
											   ,src.[value_text]
											   ,src.[meta_data]
											   ,src.[percentile]
											   ,src.[last_update_dt]
											   ,@invalidDTTM
											)

											--update changed rows and flag old as as invalid
										WHEN MATCHED  AND
										(
											
																tgt.hash_id			!= src.hash_id
												AND				tgt.invalid_dt		= @invalidDTTM
										)
										THEN UPDATE
										SET
							
											   tgt.[invalid_dt]		=	 src.[last_update_dt]

										 --update deleted rows from source as invalid
										WHEN NOT MATCHED BY SOURCE AND
										(
												tgt.invalid_dt		=	@invalidDTTM
										)
										THEN UPDATE
											SET	
												tgt.[invalid_dt]	=	getdate()

										;


								/***
								=============================================================================
		
								LOG SUCCESS TO EXECUTION LOG

								=============================================================================
								***/		

									INSERT INTO [mart].[factAggregateMetricExecutionLog]
											   ([metric_id]
											   ,[procName]
											   ,[begin_dttm]
											   ,[end_dttm]
											   ,[success_yn]
											   ,[errorNum]
											   ,[errorSeverity]
											   ,[errorProcedure]
											   ,[errorMessage]
											   ,[errormessageDTTM]
											   ,[InsertedRows]
											   ,[UpdatedRows]
											   ,[DeletedRows]
											   )
										 VALUES
											   (@metricID
											   ,@runningProc
											   ,@beginDTTM
											   ,getdate()
											   ,1
											   ,NULL
											   ,NULL
											   ,NULL
											   ,NULL
											   ,NULL
											   ,@insertedCount
											   ,@updatedCount
											   ,@deletedCount
						   
											   )
								;



								COMMIT	TRANSACTION
							
			END TRY
			BEGIN CATCH


						/***
						=============================================================================
		
						LOG FAILURE TO EXECUTION LOG

						=============================================================================
						***/
						BEGIN	TRANSACTION

							INSERT INTO [mart].[factAggregateMetricExecutionLog]
									   ([metric_id]
									   ,[procName]
									   ,[begin_dttm]
									   ,[end_dttm]
									   ,[success_yn]
									   ,[errorNum]
									   ,[errorSeverity]
									   ,[errorProcedure]
									   ,[errorMessage]
									   ,[errormessageDTTM]
									   ,[InsertedRows]
									   ,[UpdatedRows]
									   ,[DeletedRows]
									   )
								 VALUES
									   (
										@metricID
									   ,@runningProc
									   ,@beginDTTM
									   ,getdate()
									   ,0
									   ,ERROR_NUMBER()
									   ,ERROR_SEVERITY()
									   ,ERROR_PROCEDURE()
									   ,ERROR_MESSAGE()
									   ,getdate()
									   ,@insertedCount
									   ,@updatedCount
									   ,@deletedCount
									   )
							COMMIT	TRANSACTION
						;
				
			END CATCH;


			/***
			=============================================================================
		
			REMOVE CURRENT METRIC FROM LIST

			=============================================================================
			***/
			DELETE FROM @procRun
				WHERE row_num = @ix;



			-- Test variables
			--DECLARE @numRows INT = (select count(*) from #prep_data);
			--PRINT CONCAT(@n,' ',@ix,' ', @sql, ' ',@result,@@error,'  ',error_severity(), @numRows);

			/***
			=============================================================================
			
			PREPARE FOR NEXT METRIC
			
			=============================================================================
			***/
			SET @ix += 1;							
			SET @sql = N'';							-- Reset SQL statement
			DROP TABLE IF EXISTS #PREP_DATA;        -- Keep dropping temp table for each metric	
			DELETE FROM @mergeResultsTable;			-- Need to do this otherwise metric I-U-D counts will be cumulative for execution logs
		END;

END