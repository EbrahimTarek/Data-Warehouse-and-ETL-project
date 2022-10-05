use HappyScoopers_DW
Go
set ansi_nulls on 
go
set quoted_identifier on 
GO
create table [IncrementalLoads]
([LoadDateKey] int identity(1,1) primary key not null,
TableName nvarchar(100) not null,
LoadDate datetime not null )
on [Primary]

select * from Dim_Product
--Create Procedure to get last loaded Date
select * from HappyScoopers_Demo.dbo.Products
exec Get_LastLoadedDate @tableName = 'Dim_Product'
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

	select * from Dim_Product

USE [HappyScoopers_DW]
Go
CREATE OR ALTER PROCEDURE [dbo].[Get_LastLoadedDate]
@TableName nvarchar(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

	-- If the procedure is executed with a wrong table name, throw an error.
	IF NOT EXISTS(SELECT 1 FROM sys.tables WHERE name = @TableName AND Type = N'U')
	BEGIN
        PRINT N'The table does not exist in the data warehouse.';
        THROW 51000, N'The table does not exist in the data warehouse.', 1;
        RETURN -1;
	END
	
    -- If the table exists, but was never loaded before, there won't be a record for it in the table
	-- A record is created for the @TableName, with the minimum possible date in the LoadDate column
	IF NOT EXISTS (SELECT 1 FROM [int].[IncrementalLoads] WHERE TableName = @TableName)
		INSERT INTO [int].[IncrementalLoads]
		SELECT @TableName, '1753-01-01'

    -- Select the LoadDate for the @TableName
	SELECT 
		[LoadDate] AS [LoadDate]
    FROM [int].[IncrementalLoads]
    WHERE 
		[TableName] = @TableName;
    RETURN 0;
END;


--Create Lineage Key
CREATE TABLE [dbo].[Lineage]
(
	[LineageKey]		[int] IDENTITY(1,1) NOT NULL,
	[TableName]			[nvarchar](200) NOT NULL,
	[StartLoad]			[datetime]	NOT NULL,
	[FinishLoad]		[datetime]	NULL,
	[LastLoadedDate]	[datetime] NOT NULL,
	[Type]				[nvarchar](1) NOT NULL,
	[Status]			[nvarchar](1) NOT NULL,
 CONSTRAINT [PK_Integration_Lineage] PRIMARY KEY CLUSTERED ([LineageKey] ASC)
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[Lineage] ADD  CONSTRAINT [DF_Lineage_Type]  DEFAULT (N'F') FOR [Type]
Go
ALTER TABLE [dbo].[Lineage] ADD  CONSTRAINT [DF_Lineage_Status]  DEFAULT (N'P') FOR [Status]


select * from Lineage

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

--Load data from database in staging table (product table)
DECLARE @LoadType nvarchar(1) = 'I'
DECLARE @TableName nvarchar(100) = 'Dim_Product';
DECLARE @Prev_LastLoadedDate datetime;
DECLARE @LastLoadedDate datetime;
DECLARE @LineageKey int;

DECLARE @lineage TABLE (lineage int)
DECLARE @lastload TABLE (load_date datetime)

--STEP 1: Set into the @LastLoadedDate the date which will be used to retrieve elements from the source tables
select @LastLoadedDate = GETDATE()

--STEP 2: Insert a new row into the lineage table, to keep track of the new Dim_Product load that just started
--STEP 3: Store the key of the new row in the @LineageKey variable, for future usage
insert into @lineage exec [dbo].[Get_LineageKey] @LoadType , @TableName , @LastLoadedDate
select top 1 @LineageKey = lineage from @lineage

----STEP 4: Make sure that the Staging_Product table is empty before loading new information in it
TRUNCATE TABLE Staging_Product

--STEP 5: Retrieve the date when Dim_Product was last loaded
--STEP 6: Store this date into the @Prev_LastLoadedDate variable
 INSERT INTO @lastload EXEC [dbo].[Get_LastLoadedDate] @TableName
 SELECT TOP 1 @Prev_LastLoadedDate = load_date FROM @lastload
SELECT @Prev_LastLoadedDate AS [Date of the previous load]

SELECT * 
FROM [HappyScoopers_Demo].[dbo]. Products prod
LEFT JOIN [HappyScoopers_Demo].[dbo].[ProductSubcategories] subcat ON prod.SubcategoryID = subcat.ProductSubcategoryID
LEFT JOIN [HappyScoopers_Demo].[dbo].[ProductCategories] cat ON subcat.ProductCategoryID = cat.CategoryID
LEFT JOIN [HappyScoopers_Demo].[dbo].[ProductDepartments] dep ON cat.DepartmentID = dep.DepartmentID
LEFT JOIN [HappyScoopers_Demo].[dbo].[UnitsOfMeasure] um ON prod.UnitOfMeasureID = um.UnitOfMeasureID
WHERE prod.ModifiedDate > @Prev_LastLoadedDate AND prod.ModifiedDate <= @LastLoadedDate


--STEP 7: Insert into the staging table new products or products that were modified after the last Dim_Product load finished 
INSERT INTO [dbo].[Staging_Product]
	EXEC [HappyScoopers_Demo].[dbo].[Load_StagingProduct] @Prev_LastLoadedDate, @LastLoadedDate

-- Take a look what the staging table contains 
SELECT * FROM Staging_Product

--STEP 8: Transfer information from the staging table to the actual dimension table: Dim_Product
EXEC [dbo].[Load_DimProduct]

-- Take a look what Dim_Product contains
SELECT * FROM Dim_Product





























