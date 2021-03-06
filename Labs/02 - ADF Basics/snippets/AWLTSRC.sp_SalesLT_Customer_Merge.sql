/****** Object:  StoredProcedure [AWLTSRC].[sp_SalesLT_Customer_Merge]    Script Date: 2/17/2019 11:41:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [AWLTSRC].[sp_SalesLT_Customer_Merge]
 @BatchId BIGINT = -1
,@ETLControlId INT = -1
,@ETLAuditLogId BIGINT = NULL
,@SourceSystem VARCHAR(50)
,@SourceName VARCHAR(50) 
,@SinkName VARCHAR(50) 	
,@LogType VARCHAR(50)
,@PipelineId VARCHAR(50) = NULL
,@PipelineName VARCHAR(50) = NULL
,@PipelineTriggerType VARCHAR(50) = NULL
,@ActivityName VARCHAR(50) = NULL
,@ActivityId VARCHAR(50) = NULL
,@Source [AWLTSRC].[SalesLT_CustomerType] READONLY
AS
BEGIN
  
  SET NOCOUNT ON;

  DECLARE 
     @CurrentDateTime DATETIME2(3) = CURRENT_TIMESTAMP
	,@ProcedureName sysname = OBJECT_NAME(@@PROCID)
	,@RowsInserted INT = 0
	,@RowsUpdated INT = 0
	,@ErrorMsg NVARCHAR(max)  
	,@ErrorSeverity INT  
	,@ErrorState INT; 

  DECLARE @MergeSummary TABLE(ActionType NVARCHAR(10));
  
  BEGIN TRY 

  MERGE [AWLTSRC].[SalesLT_Customer] AS target
  USING ( 
  SELECT *
  ,CONVERT(NCHAR(40), HASHBYTES('SHA1', CONCAT('|', CONVERT(NVARCHAR(MAX), [NameStyle]), '|', CONVERT(NVARCHAR(MAX), [Title]), '|', CONVERT(NVARCHAR(MAX), [FirstName]), '|', CONVERT(NVARCHAR(MAX), [MiddleName]), '|', CONVERT(NVARCHAR(MAX), [LastName]), '|', CONVERT(NVARCHAR(MAX), [Suffix]), '|', CONVERT(NVARCHAR(MAX), [CompanyName]), '|', CONVERT(NVARCHAR(MAX), [SalesPerson]), '|', CONVERT(NVARCHAR(MAX), [EmailAddress]), '|', CONVERT(NVARCHAR(MAX), [Phone]), '|', CONVERT(NVARCHAR(MAX), [PasswordHash]), '|', CONVERT(NVARCHAR(MAX), [PasswordSalt]), '|', CONVERT(NVARCHAR(MAX), [rowguid]), '|', CONVERT(NVARCHAR(MAX), [ModifiedDate]))), 2) AS ChangeHashKey
  FROM @Source
  ) AS source
  -- Add Hashbytes to only update records that change
  ON (target.CustomerID = source.CustomerID )
  WHEN MATCHED  AND target.ChangeHashKey != source.ChangeHashKey THEN
      UPDATE SET 
	              NameStyle = source.NameStyle
				 ,Title = source.Title
				 ,FirstName = source.FirstName
	             ,MiddleName = source.MiddleName
				 ,LastName = source.LastName
				 ,Suffix = source.Suffix
				 ,CompanyName = source.CompanyName
				 ,SalesPerson = source.SalesPerson
				 ,EmailAddress = source.EmailAddress
				 ,Phone = source.Phone
				 ,PasswordHash = source.PasswordHash
				 ,PasswordSalt = source.PasswordSalt
				 ,rowguid = source.rowguid
				 ,ModifiedDate = source.ModifiedDate
				 ,ChangeHashKey = source.ChangeHashKey
				 ,UpdateBatchId = @BatchId
				 ,UpdateDateTime = CURRENT_TIMESTAMP


  WHEN NOT MATCHED THEN
      INSERT (CustomerID, NameStyle, Title, FirstName, MiddleName, LastName, Suffix, CompanyName, SalesPerson, EmailAddress, Phone, PasswordHash, PasswordSalt, rowguid, ModifiedDate, ChangeHashKey, CreateBatchId, CreateDateTime, UpdateBatchId, UpdateDateTime )
      VALUES (source.CustomerID, source.NameStyle, Source.Title, source.FirstName, source.MiddleName, source.LastName, source.Suffix, source.CompanyName, source.SalesPerson, source.EmailAddress, source.Phone, source.PasswordHash, source.PasswordSalt, source.rowguid, source.ModifiedDate, source.ChangeHashKey, @BatchId, CURRENT_TIMESTAMP, @BatchId, CURRENT_TIMESTAMP)
   OUTPUT $action INTO @MergeSummary;  
 
    -- Capture RowCounts
	SELECT @RowsInserted = COUNT(IIF(ActionType = 'INSERT', 1, NULL)) 
		,@RowsUpdated = COUNT(IIF(ActionType = 'UPDATE', 1, NULL)) 				
	FROM @MergeSummary;

END TRY

BEGIN CATCH
	
	SELECT @ErrorMsg = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();		 
	THROW;

END CATCH

END