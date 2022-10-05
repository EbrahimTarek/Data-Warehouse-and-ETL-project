--Stored Procedures For Dimension Tables

create procedure dbo.Load_DimCustomer
as
begin
	set nocount on 
	set xact_abort on 
	declare @EndOftime datetime = '9999-12-31'
	declare @LastDateLoaded datetime
	begin tran
	--Get the Lineage of the current load of Dim_Customer
	declare @LineageKey int = 
	(select top 1 LineageKey from lineage
		where TableName = 'Dim_Customer' and FinishLoad is null 
		order by LineageKey desc )

	/* Update the Validity date of Modified Customer in Dim_Customer
	The Rows will not be active anymore,because the stagging table holds newer versions */
	
	update initial
	set inital.[Valid To] = modif.[Valid From]
	from Dim_Cutomer as initial , Stagging_Customer as modif
	where initial.[_Source Key] = modif.[_Source Key]
	and modif.[Valid To] = @EndOftime

	insert into Dim_Customer([_Source Key],[First Name],[Last Name],Title,[Delivery Location Key],[Billing Location Key]
							,[Phone Number],Email,[Valid From],[Valid To],[Lineage Key])
	select [_Source Key],[First Name] ,[Last Name],[Title],[Delivery Location Key],[Billing Location Key]
           ,[Phone Number],[Email],[Valid From],[Valid To],@LineageKey
	from staging_Customer

	/* update the lineage table for the most current Dim_Customer load with the Finish date and
	'S' in the Status Column ,meaning that Load Finished Successfully */
	update dbo.lineage
	set 
		FinishLoad = SYSDATETIME(),
		Status = 'S',
		@LastDateLoaded = LastLoadedDate
		where lineageKey = @LineageKey
	
	/*Update the LoadDates table with the most current load date for Dim_Customer */
	update [IncrementalLoads]
		set loadDate = @LastDateLoaded
		where TableName = 'Dim_Customer'
	-- All these tasks happen together or don't happen at all
	Commit
	return 0
End

Create procedure dbo.Load_DimDate(@StartDate date = '2000-01-01' , @EndDate date = '2025-01-01')
as
begin
	set nocount on
	set xact_abort on

	truncate table dim_date 

	declare @EndOfTime datetime = '9999-12-31'
	declare @LastDateLoaded datetime

	Begin tran
	declare @lineageKey int = (select top 1 LineageKey 
								from dbo.Lineage
								where [TableName] = 'dim_date'
								and FinishLoad is null
								order by LineageKey desc
								)
	while (@StartDate < @EndDate )
	begin
   INSERT INTO [dbo].[Dim_Date] (
			[Date Key]
           ,[Date]
           ,[Day]
           ,[Day Suffix]
           ,[Weekday]
           ,[Weekday Name]
           ,[Weekday Name Short]
           ,[Weekday Name FirstLetter]
           ,[Day Of Year]
           ,[Week Of Month]
           ,[Week Of Year]
           ,[Month]
           ,[Month Name]
           ,[Month Name Short]
           ,[Month Name FirstLetter]
           ,[Quarter]
           ,[Quarter Name]
           ,[Year]
           ,[MMYYYY]
           ,[Month Year]
           ,[Is Weekend]
           ,[Is Holiday]
           ,[Holiday Name]
           ,[Special Day]
           ,[First Date Of Year]
           ,[Last Date Of Year]
           ,[First Date Of Quater]
           ,[Last Date Of Quater]
           ,[First Date Of Month]
           ,[Last Date Of Month]
           ,[First Date Of Week]
           ,[Last Date Of Week]
		   ,[Lineage Key]
      )
   SELECT DateKey = YEAR(@StartDate) * 10000 + MONTH(@StartDate) * 100 + DAY(@StartDate),
      DATE = @StartDate,
      Day = DAY(@StartDate),
      [DaySuffix] = CASE 
         WHEN DAY(@StartDate) = 1
            OR DAY(@StartDate) = 21
            OR DAY(@StartDate) = 31
            THEN 'st'
         WHEN DAY(@StartDate) = 2
            OR DAY(@StartDate) = 22
            THEN 'nd'
         WHEN DAY(@StartDate) = 3
            OR DAY(@StartDate) = 23
            THEN 'rd'
         ELSE 'th'
         END,
      WEEKDAY = DATEPART(dw, @StartDate),
      WeekDayName = DATENAME(dw, @StartDate),
      WeekDayName_Short = UPPER(LEFT(DATENAME(dw, @StartDate), 3)),
      WeekDayName_FirstLetter = LEFT(DATENAME(dw, @StartDate), 1),
      [DayOfYear] = DATENAME(dy, @StartDate),
      [WeekOfMonth] = DATEPART(WEEK, @StartDate) - DATEPART(WEEK, DATEADD(MM, DATEDIFF(MM, 0, @StartDate), 0)) + 1,
      [WeekOfYear] = DATEPART(wk, @StartDate),
      [Month] = MONTH(@StartDate),
      [MonthName] = DATENAME(mm, @StartDate),
      [MonthName_Short] = UPPER(LEFT(DATENAME(mm, @StartDate), 3)),
      [MonthName_FirstLetter] = LEFT(DATENAME(mm, @StartDate), 1),
      [Quarter] = DATEPART(q, @StartDate),
      [QuarterName] = CASE 
         WHEN DATENAME(qq, @StartDate) = 1
            THEN 'First'
         WHEN DATENAME(qq, @StartDate) = 2
            THEN 'second'
         WHEN DATENAME(qq, @StartDate) = 3
            THEN 'third'
         WHEN DATENAME(qq, @StartDate) = 4
            THEN 'fourth'
         END,
      [Year] = YEAR(@StartDate),
      [MMYYYY] = RIGHT('0' + CAST(MONTH(@StartDate) AS VARCHAR(2)), 2) + CAST(YEAR(@StartDate) AS VARCHAR(4)),
      [MonthYear] = CAST(YEAR(@StartDate) AS VARCHAR(4)) + UPPER(LEFT(DATENAME(mm, @StartDate), 3)),
      [IsWeekend] = CASE 
         WHEN DATENAME(dw, @StartDate) = 'Sunday'
            OR DATENAME(dw, @StartDate) = 'Saturday'
            THEN 1
         ELSE 0
         END,
      [IsHoliday] = 0,
[HolidayName] =	CONVERT(varchar(20), ''),
[SpecialDays] =	CONVERT(varchar(20), ''),
[FirstDateofYear]   = CAST(CAST(YEAR(@StartDate) AS VARCHAR(4)) + '-01-01' AS DATE),
[LastDateofYear]    = CAST(CAST(YEAR(@StartDate) AS VARCHAR(4)) + '-12-31' AS DATE),
[FirstDateofQuater] = DATEADD(qq, DATEDIFF(qq, 0, GETDATE()), 0),
[LastDateofQuater]  = DATEADD(dd, - 1, DATEADD(qq, DATEDIFF(qq, 0, GETDATE()) + 1, 0)),
[FirstDateofMonth]  = CAST(CAST(YEAR(@StartDate) AS VARCHAR(4)) + '-' + CAST(MONTH(@StartDate) AS VARCHAR(2)) + '-01' AS DATE),
[LastDateofMonth]   = EOMONTH(@StartDate),
[FirstDateofWeek]   = DATEADD(dd, - (DATEPART(dw, @StartDate) - 1), @StartDate),
[LastDateofWeek] = DATEADD(dd, 7 - (DATEPART(dw, @StartDate)), @StartDate),
@LineageKey


   SET @StartDate = DATEADD(DD, 1, @StartDate)
END

--Update Holiday information
UPDATE Dim_Date
SET [Is Holiday] = 1,
   [Holiday Name] = 'Christmas'
WHERE [Month] = 12
   AND [Day] = 25

UPDATE Dim_Date
SET [Special Day] = 'Valentines Day'
WHERE [Month] = 2
   AND [Day] = 14


SELECT * FROM Dim_Date


    
	-- Update the lineage table for the most current Dim_Date load with the finish date and 
	-- 'S' in the Status column, meaning that the load finished successfully
	UPDATE [dbo].Lineage
        SET 
			FinishLoad = SYSDATETIME(),
            Status = 'S',
			@LastDateLoaded = LastLoadedDate
    WHERE [LineageKey] = @LineageKey;
	 
	
	-- Update the LoadDates table with the most current load date for Dim_Date
	UPDATE [dbo].[IncrementalLoads]
        SET [LoadDate] = @LastDateLoaded
    WHERE [TableName] = N'Dim_Date';

    -- All these tasks happen together or don't happen at all. 
	COMMIT;

    RETURN 0;
END;


create procedure dbo.load_employee
as
begin
	set nocount on
	set xact_abort on 

	declare @EndOfTime datetime = '9999-12-31'
	declare @LastDateLoaded datetime

	begin tran
		DECLARE @LineageKey int = (SELECT TOP(1) [LineageKey]
                               FROM dbo.Lineage
                               WHERE [TableName] = N'Dim_Employee'
                               AND [FinishLoad] IS NULL
                               ORDER BY [LineageKey] DESC);
    UPDATE emp
    SET emp.[Valid To] = mod_emp.[Valid From]
    FROM 
		Dim_Employee AS emp INNER JOIN 
		Staging_Employee AS mod_emp ON emp.[_Source Key] = mod_emp.[_Source Key]
    WHERE emp.[Valid To] = @EndOfTime

    -- Insert new rows for the modified products
	INSERT Dim_Employee
		   ([_Source Key]
           ,[Location Key]
           ,[Last Name]
           ,[First Name]
           ,[Title]
           ,[Birth Date]
           ,[Gender]
           ,[Hire Date]
           ,[Job Title]
           ,[Address Line]
           ,[City]
           ,[Country]
           ,[Manager Key]
           ,[Valid From]
           ,[Valid To]
           ,[Lineage Key])
    SELECT [_Source Key]
           ,[Location Key]
           ,[Last Name]
           ,[First Name]
           ,[Title]
           ,[Birth Date]
           ,[Gender]
           ,[Hire Date]
           ,[Job Title]
           ,[Address Line]
           ,[City]
           ,[Country]
           ,[Manager Key]
           ,[Valid From]
           ,[Valid To]
           ,@LineageKey
    FROM Staging_Employee;

    
	-- Update the lineage table for the most current Dim_Product load with the finish date and 
	-- 'S' in the Status column, meaning that the load finished successfully
	UPDATE [dbo].Lineage
        SET 
			FinishLoad = SYSDATETIME(),
            Status = 'S',
			@LastDateLoaded = LastLoadedDate
    WHERE [LineageKey] = @LineageKey;
	 
	
	-- Update the LoadDates table with the most current load date for Dim_Product
	UPDATE [dbo].[IncrementalLoads]
        SET [LoadDate] = @LastDateLoaded
    WHERE [TableName] = N'Dim_Employee';

    -- All these tasks happen together or don't happen at all. 
	COMMIT;

    RETURN 0;
END;


CREATE  PROCEDURE [dbo].[Load_DimLocation]
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @EndOfTime datetime =  '9999-12-31';
	DECLARE @LastDateLoaded datetime;

    BEGIN TRAN;

    -- Get the lineage of the current load of Dim_Product
	DECLARE @LineageKey int = (SELECT TOP(1) [LineageKey]
                               FROM dbo.Lineage
                               WHERE [TableName] = N'Dim_Location'
                               AND [FinishLoad] IS NULL
                               ORDER BY [LineageKey] DESC);

	-- Update the validity date of modified products in Dim_Location. 
	-- The rows will not be active anymore, because the staging table holds newer versions
    UPDATE initial
    SET initial.[Valid To] = modif.[Valid From]
    FROM 
		Dim_Location AS initial INNER JOIN 
		Staging_Location AS modif ON initial.[_Source Key] = modif.[_Source Key]
    WHERE initial.[Valid To] = @EndOfTime

    -- Insert new rows for the modified products
	INSERT Dim_Location
           ([_Source Key]
           ,[Continent]
           ,[Region]
           ,[Subregion]
           ,[Country Code]
           ,[Country]
           ,[Country Formal Name]
           ,[Country Population]
           ,[Province Code]
           ,[Province]
           ,[Province Population]
           ,[City]
           ,[City Population]
           ,[Address Line 1]
           ,[Address Line 2]
           ,[Postal Code]
           ,[Valid From]
           ,[Valid To]
           ,[Lineage Key])
    
	SELECT  [_Source Key]
           ,[Continent]
           ,[Region]
           ,[Subregion]
           ,[Country Code]
           ,[Country]
           ,[Country Formal Name]
           ,[Country Population]
           ,[Province Code]
           ,[Province]
           ,[Province Population]
           ,[City]
           ,[City Population]
           ,[Address Line 1]
           ,[Address Line 2]
           ,[Postal Code]
           ,[Valid From]
           ,[Valid To]
           ,@LineageKey
    FROM Staging_Location;

    
	-- Update the lineage table for the most current Dim_Location load with the finish date and 
	-- 'S' in the Status column, meaning that the load finished successfully
	UPDATE [dbo].Lineage
        SET 
			FinishLoad = SYSDATETIME(),
            Status = 'S',
			@LastDateLoaded = LastLoadedDate
    WHERE [LineageKey] = @LineageKey;
	 
	
	-- Update the LoadDates table with the most current load date for Dim_Product
	UPDATE [dbo].[IncrementalLoads]
        SET [LoadDate] = @LastDateLoaded
    WHERE [TableName] = N'Dim_Location';

    -- All these tasks happen together or don't happen at all. 
	COMMIT;

    RETURN 0;
END;



CREATE PROCEDURE [dbo].[Load_DimPaymentType]
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @EndOfTime datetime =  '9999-12-31';
	DECLARE @LastDateLoaded datetime;

    BEGIN TRAN;

    -- Get the lineage of the current load of Dim_PaymentType
	DECLARE @LineageKey int = (SELECT TOP(1) [LineageKey]
                               FROM dbo.Lineage
                               WHERE [TableName] = N'Dim_PaymentType'
                               AND [FinishLoad] IS NULL
                               ORDER BY [LineageKey] DESC);

	    IF NOT EXISTS (SELECT * FROM Dim_Payment WHERE [_Source Key] = '')
			INSERT INTO [dbo].[Dim_Payment]
				   ([_Source Key]
				   ,[Payment Type Name]
				   ,[Valid From]
				   ,[Valid To]
				   ,[Lineage Key])
			 VALUES
				   ('', 'N/A', '1753-01-01', '9999-12-31', -1)

	
	-- Update the validity date of modified PaymentTypes in Dim_PaymentType. 
	-- The rows will not be active anymore, because the staging table holds newer versions
    UPDATE initial
    SET initial.[Valid To] = modif.[Valid From]
    FROM 
		Dim_Payment AS initial INNER JOIN 
		Staging_PaymentType AS modif ON initial.[_Source Key] = modif.[_Source Key]
    WHERE initial.[Valid To] = @EndOfTime

    -- Insert new rows for the modified PaymentTypes
	INSERT Dim_Payment
           ([_Source Key]
           ,[Payment Type Name]
           ,[Valid From]
           ,[Valid To]
           ,[Lineage Key])
    
	SELECT  [_Source Key]
           ,[Payment Type Name]
           ,[Valid From]
           ,[Valid To]
           ,@LineageKey
    FROM Staging_PaymentType;

    
	-- Update the lineage table for the most current Dim_PaymentType load with the finish date and 
	-- 'S' in the Status column, meaning that the load finished successfully
	UPDATE [dbo].Lineage
        SET 
			FinishLoad = SYSDATETIME(),
            Status = 'S',
			@LastDateLoaded = LastLoadedDate
    WHERE [LineageKey] = @LineageKey;
	 
	
	-- Update the LoadDates table with the most current load date for Dim_PaymentType
	UPDATE [dbo].[IncrementalLoads]
        SET [LoadDate] = @LastDateLoaded
    WHERE [TableName] = N'Dim_PaymentType';

    -- All these tasks happen together or don't happen at all. 
	COMMIT;

    RETURN 0;
END;

CREATE PROCEDURE [dbo].[Load_DimProduct]
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @EndOfTime datetime =  '9999-12-31';
	DECLARE @LastDateLoaded datetime;

    BEGIN TRAN;

    -- Get the lineage of the current load of Dim_Product
	DECLARE @LineageKey int = (SELECT TOP(1) [LineageKey]
                               FROM dbo.Lineage
                               WHERE [TableName] = N'Dim_Product'
                               AND [FinishLoad] IS NULL
                               ORDER BY [LineageKey] DESC);


	IF NOT EXISTS (SELECT * FROM Dim_Product WHERE [_Source Key] = '')
INSERT INTO [dbo].[Dim_Product]
           ([_Source Key]
           ,[Product Name]
           ,[Product Code]
           ,[Product Description]
           ,[Product Subcategory]
           ,[Product Category]
           ,[Product Department]
           ,[Unit Of Measure Code]
           ,[Unit Of Measure Name]
           ,[Unit Price]
           ,[Discontinued]
           ,[Valid From]
           ,[Valid To]
           ,[Lineage Key])
     VALUES
           ('', 'N/A', 'N/A','N/A','N/A','N/A','N/A','N/A','N/A', -1, 'N/A', '1753-01-01', '9999-12-31', -1)

	-- Update the validity date of modified products in Dim_Product. 
	-- The rows will not be active anymore, because the staging table holds newer versions
    UPDATE prod
    SET prod.[Valid To] = mprod.[Valid From]
    FROM 
		Dim_Product AS prod INNER JOIN 
		Staging_Product AS mprod ON prod.[_Source Key] = mprod.[_Source Key]
    WHERE prod.[Valid To] = @EndOfTime

    -- Insert new rows for the modified products
	INSERT Dim_Product
		    ([_Source Key]
           ,[Product Name]
           ,[Product Code]
           ,[Product Description]
           ,[Product Subcategory]
           ,[Product Category]
           ,[Product Department]
           ,[Unit Of Measure Code]
           ,[Unit Of Measure Name]
           ,[Unit Price]
           ,[Discontinued]
           ,[Valid From]
           ,[Valid To]
           ,[Lineage Key])
    SELECT [_Source Key]
           ,[Product Name]
           ,[Product Code]
           ,[Product Description]
           ,[Product Subcategory]
           ,[Product Category]
           ,[Product Department]
           ,[Unit Of Measure Code]
           ,[Unit Of Measure Name]
           ,[Unit Price]
           ,[Discontinued]
           ,[Valid From]
           ,[Valid To]
           ,@LineageKey
    FROM Staging_Product;

    
	-- Update the lineage table for the most current Dim_Product load with the finish date and 
	-- 'S' in the Status column, meaning that the load finished successfully
	UPDATE [dbo].Lineage
        SET 
			FinishLoad = SYSDATETIME(),
            Status = 'S',
			@LastDateLoaded = LastLoadedDate
    WHERE [LineageKey] = @LineageKey;
	 
	
	-- Update the LoadDates table with the most current load date for Dim_Product
	UPDATE [dbo].[IncrementalLoads]
        SET [LoadDate] = @LastDateLoaded
    WHERE [TableName] = N'Dim_Product';

    -- All these tasks happen together or don't happen at all. 
	COMMIT;

    RETURN 0;
END;



CREATE PROCEDURE [dbo].[Load_DimPromotion]
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @EndOfTime datetime =  '9999-12-31';
	DECLARE @LastDateLoaded datetime;

    BEGIN TRAN;

    -- Get the lineage of the current load of Dim_Promotion
	DECLARE @LineageKey int = (SELECT TOP(1) [LineageKey]
                               FROM dbo.Lineage
                               WHERE [TableName] = N'Dim_Promotion'
                               AND [FinishLoad] IS NULL
                               ORDER BY [LineageKey] DESC);

	IF NOT EXISTS (SELECT * FROM [Dim_Promotion] WHERE [_Source Key] = '')
		INSERT INTO [dbo].[Dim_Promotion]
				   ([_Source Key]
				   ,[Deal Description]
				   ,[Start Date]
				   ,[End Date]
				   ,[Discount Amount]
				   ,[Discount Percentage]
				   ,[Valid From]
				   ,[Valid To]
				   ,[Lineage Key])
		 VALUES
			   ('', 'N/A', '1753-01-01', '1753-01-01', -1, -1, '1753-01-01', '9999-12-31', -1)


	-- Update the validity date of modified Promotions in Dim_Promotion. 
	-- The rows will not be active anymore, because the staging table holds newer versions
    UPDATE initial
    SET initial.[Valid To] = modif.[Valid From]
    FROM 
		Dim_Promotion AS initial INNER JOIN 
		Staging_Promotion AS modif ON initial.[_Source Key] = modif.[_Source Key]
    WHERE initial.[Valid To] = @EndOfTime

    -- Insert new rows for the modified Promotions
	INSERT Dim_Promotion
           ([_Source Key]
           ,[Deal Description]
           ,[Start Date]
           ,[End Date]
           ,[Discount Amount]
           ,[Discount Percentage]
           ,[Valid From]
           ,[Valid To]
           ,[Lineage Key])
    
	SELECT  [_Source Key]
           ,[Deal Description]
           ,[Start Date]
           ,[End Date]
           ,[Discount Amount]
           ,[Discount Percentage]
           ,[Valid From]
           ,[Valid To]
           ,@LineageKey
    FROM Staging_Promotion;

    
	-- Update the lineage table for the most current Dim_Promotion load with the finish date and 
	-- 'S' in the Status column, meaning that the load finished successfully
	UPDATE [dbo].Lineage
        SET 
			FinishLoad = SYSDATETIME(),
            Status = 'S',
			@LastDateLoaded = LastLoadedDate
    WHERE [LineageKey] = @LineageKey;
	 
	
	-- Update the LoadDates table with the most current load date for Dim_Promotion
	UPDATE [dbo].[IncrementalLoads]
        SET [LoadDate] = @LastDateLoaded
    WHERE [TableName] = N'Dim_Promotion';

    -- All these tasks happen together or don't happen at all. 
	COMMIT;

    RETURN 0;
END;


  Create or alter procedure dbo.[load_FactSales]
  as
  begin
	set nocount on 
	set xact_abort on 

	declare @EndOfTime datetime = '9999-12-31'
	declare @LastLDateLoaded datetime

	begin tran
		--select lineage , for logging purposes . This will be used in the ETL load
		declare @lineageKey int = isnull((SELECT TOP(1) [LineageKey]
								   FROM dbo.Lineage 
								   where tablename = N'Fact_Sales' AND [FinishLoad] IS NULL
									ORDER BY [LineageKey] DESC), -1);
		
		--Update the surrogate key columns in the stagging table 
		update s
		set s.[Customer Key] = (
		 coalesce((select top 1 c.[customer Key] 
			from Dim_Customer c
			where REPLACE(c.[_Source Key],'HSD|','') = s.[_SourceCustomerKey]
			AND s.[ModifiedDate] >= c.[Valid From] AND s.[ModifiedDate] < c.[Valid To]
			ORDER BY c.[Valid From]),
		(SELECT TOP (1) c.[Customer Key] FROM Dim_Customer AS c WHERE c.[_Source Key] = '')
		,0)),
		
		s.[Employee Key] =  COALESCE((
								SELECT TOP(1) e.[Employee Key]
                                FROM Dim_Employee AS e
                                WHERE REPLACE(e.[_Source Key], 'HSD|', '') = s.[_SourceEmployeeKey]
                               	--AND e.[Valid To] = '9999-12-31'
							     AND s.[ModifiedDate] >= e.[Valid From]
								 AND s.[ModifiedDate] < e.[Valid To]
								ORDER BY e.[Valid From])
								, (
								SELECT TOP (1) e.[Employee Key]
								FROM Dim_Employee AS e
								WHERE e.[_Source Key] = ''
							), 0),
		s.[Product Key] = COALESCE((
								SELECT TOP(1) p.[Product Key]
                                FROM Dim_Product AS p
                                WHERE REPLACE(p.[_Source Key], 'HSD|', '') = s.[_SourceProductKey]
                                    --AND p.[Valid To] = '9999-12-31'
									AND s.[ModifiedDate] >= p.[Valid From]
                                    AND s.[ModifiedDate] < p.[Valid To]
								ORDER BY p.[Valid From]
								), (
								SELECT TOP (1) p.[Product Key]
								FROM Dim_Product AS p
								WHERE p.[_Source Key] = ''
							), 0),
		s.[Payment Type Key] = COALESCE((
								SELECT TOP(1) pm.[Payment Type Key]
                                FROM Dim_Payment AS pm
                                WHERE REPLACE(pm.[_Source Key], 'HSD|', '') = s.[_SourcePaymentTypeKey]
                                    --AND pm.[Valid To] = '9999-12-31'
									AND s.[ModifiedDate] >= pm.[Valid From]
                                    AND s.[ModifiedDate] < pm.[Valid To]
								ORDER BY pm.[Valid From]
								), (
								SELECT TOP (1) pm.[Payment Type Key]
								FROM Dim_Payment AS pm
								WHERE pm.[_Source Key] = ''
							), 0),
		s.[Delivery Location Key] = COALESCE((
								SELECT TOP(1) l.[Location Key]
                                FROM Dim_Location AS l
                                WHERE REPLACE(l.[_Source Key], 'HSD|', '') = s.[_SourceDeliveryLocationKey]
                                    --AND l.[Valid To] = '9999-12-31'
									AND s.[ModifiedDate] >= l.[Valid From]
                                    AND s.[ModifiedDate] < l.[Valid To]
								ORDER BY l.[Valid From]
								), (
								SELECT TOP (1) l.[Location Key]
								FROM Dim_Location AS l
								WHERE l.[_Source Key] = ''
							), 0),
		s.[Promotion Key] = COALESCE((
							SELECT TOP(1) p.[Promotion Key]
                            FROM Dim_Promotion AS p
                            WHERE REPLACE(p.[_Source Key], 'HSD|', '') = s.[_SourcePromotionKey]
                                 --AND p.[Valid To] = '9999-12-31'
								 AND s.[ModifiedDate] >= p.[Valid From]
                                 AND s.[ModifiedDate] < p.[Valid To]
							ORDER BY p.[Valid From]
							), (
							SELECT TOP (1) p.[Promotion Key]
							FROM Dim_Promotion AS p
							WHERE p.[_Source Key] = ''
							), 0),
		s.[Order Date Key] = COALESCE((SELECT TOP(1) d.[Date Key]
                                           FROM Dim_Date AS d
                                           WHERE d.[Date] = s.[_SourceOrderDateKey]
									       ), 0),
		s.[Delivery Date Key] = COALESCE((SELECT TOP(1) d.[Date Key]
                                           FROM Dim_Date AS d
                                           WHERE d.[Date] = s.[_SourceDeliveryDateKey]
									       ), 0)
    FROM [dbo].[Stagging_Sales] AS s;
		
	--delete data from the fact table that is present now in the stagging table 
	delete s
	from Fact_Sales s
	where s._SourceOrder in (select _SourceOrder from Stagging_Sales)

-- Perform a simple insert from staging to the fact
INSERT INTO [dbo].[Fact_Sales]
           ([Customer Key]
           ,[Employee Key]
           ,[Product Key]
           ,[Payment Type Key]
           ,[Order Date Key]
           ,[Delivery Date Key]
           ,[Delivery Location Key]
           ,[Promotion Key]
           ,[Description]
           ,[Package]
           ,[Quantity]
           ,[Unit Price]
           ,[VAT Rate]
           ,[Total Excluding VAT]
           ,[VAT Amount]
           ,[Total Including VAT]
           ,[_SourceOrder]
           ,[_SourceOrderLine]
           ,[Lineage Key])
SELECT 
			[Customer Key]
           ,[Employee Key]
           ,[Product Key]
           ,[Payment Type Key]
           ,[Order Date Key]
           ,[Delivery Date Key]
           ,[Delivery Location Key]
           ,[Promotion Key]
           ,[Description]
           ,[Package]
           ,[Quantity]
           ,[Unit Price]
           ,[VAT Rate]
           ,[Total Excluding VAT]
           ,[VAT Amount]
           ,[Total Including VAT]
           ,[_SourceOrder]
           ,[_SourceOrderLine]
		   ,@LineageKey
	FROM [dbo].[Stagging_Sales]
	-- Update the lineage table for the most current Dim_Customer load with the finish date and 
	-- 'S' in the Status column, meaning that the load finished successfully
	UPDATE [dbo].Lineage
        SET 
			FinishLoad = SYSDATETIME(),
            Status = 'S',
			@LastLDateLoaded = LastLoadedDate
    WHERE [LineageKey] = @LineageKey;
	 
	
	-- Update the LoadDates table with the most current load date for Dim_Customer
	UPDATE [dbo].[IncrementalLoads]
        SET [LoadDate] = @LastLDateLoaded
    WHERE [TableName] = N'Fact_Sales';

    -- All these tasks happen together or don't happen at all. 
	COMMIT;

    RETURN 0; 
END;
 




		









