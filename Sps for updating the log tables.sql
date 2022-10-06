use HappyScoopers_DW
Go
set ansi_nulls on 
go
set quoted_identifier on 
GO
--Create Procedure to get last loaded Date
CREATE OR ALTER PROCEDURE [dbo].[Get_LastLoadedDate]
@TableName nvarchar(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

	-- If the procedure is executed with a wrong table name, throw an error.
	IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = @TableName AND Type = N'U') -- U means User definedd 
	BEGIN
        PRINT N'The table does not exist in the data warehouse.';
        THROW 51000, N'The table does not exist in the data warehouse.', 1;
        RETURN -1;
	END
	
    -- If the table exists, but was never loaded before, there won't be a record for it in the table
	-- A record is created for the @TableName, with the minimum possible date in the LoadDate column
	IF NOT EXISTS (SELECT 1 FROM [dbo].[IncrementalLoads] WHERE TableName = @TableName)
		INSERT INTO [dbo].[IncrementalLoads]
		SELECT @TableName, '1753-01-01'  -- the first possible data accepted in sql server 

    -- Select the LoadDate for the @TableName
	SELECT 
		[LoadDate] AS [LoadDate]
    FROM [dbo].[IncrementalLoads]
    WHERE 
		[TableName] = @TableName;
end



--Create procedure for dbo.lineage
CREATE OR ALTER PROCEDURE [dbo].[Get_LineageKey]
@LoadType nvarchar(1),
@TableName nvarchar(100),
@LastLoadedDate datetime
AS
BEGIN
select * from  Lineage
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
DECLARE @StartLoad datetime = SYSDATETIME();
INSERT INTO [dbo].[Lineage]([TableName],[StartLoad],[FinishLoad],[Status],[Type],[LastLoadedDate])
VALUES (@TableName,@StartLoad,NULL,'P',@LoadType,@LastLoadedDate);
IF (@LoadType = 'F')
	BEGIN
		UPDATE [dbo].[IncrementalLoads]
		SET LoadDate = '1753-01-01'
		WHERE TableName = @TableName
		EXEC('TRUNCATE TABLE ' + @TableName)
	END;
SELECT MAX([LineageKey]) AS LineageKey
FROM [int].[Lineage]
WHERE 
	[TableName] = @TableName
	AND [StartLoad] = @StartLoad
RETURN 0;
END;