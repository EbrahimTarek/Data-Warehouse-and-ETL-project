--Stored Procedures of Stagging Tables

use HappyScoopers_Demo
Go

CREATE OR ALTER PROCEDURE [dbo].[Load_StagingSales]
@LastLoadDate datetime,
@NewLoadDate datetime
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SELECT CAST(ord.OrderDate AS date)								AS [_SourceOrderDateKey],
           CAST(ord.DeliveryDate AS date)							AS [_SourceDeliveryDateKey],
           ord.OrderID												AS [_SourceOrder],
		   ISNULL(orl.OrderLineID, 0)								AS [_SourceOrderLine],
		   cus.CustomerID											AS [_SourceCustomerKey],
		   emp.EmployeeID											AS [_SourceEmployeeKey],
		   prd.ProductID											AS [_SourceProductKey],
		   pmt.PaymentTypeID										AS [_SourcePaymentTypeKey],
		   cou.CountryID											AS [_SourceDeliveryCountryKey],
		   prv.ProvinceID											AS [_SourceDeliveryProvinceKey],
		   cit.CityID												AS [_SourceDeliveryCityKey],
		   adr.AddressID											AS [_SourceDeliveryAddressKey],
		   CONCAT_WS('|', cou.CountryID, 
			prv.ProvinceID,
			cit.CityID,
			adr.AddressID)											AS [_SourceDeliveryLocationKey],
		   pro.PromotionID											AS [_SourcePromotionKey],
		   ISNULL(orl.Description, 'N/A)')							AS [Description],
           ISNULL(pck.PackageTypeName, 'N/A')						AS [Package],
           orl.Quantity												AS [Quantity],
           orl.UnitPrice											AS [Unit Price],
           ISNULL(orl.VATRate, 0.20)								AS [VAT Rate],
           orl.Quantity * orl.UnitPrice								AS [Total Excluding VAT],
		   orl.Quantity * orl.UnitPrice * ISNULL(orl.VATRate, 0.20) AS [VAT Amount],
		   orl.Quantity*orl.UnitPrice*(1+ ISNULL(orl.VATRate, 0.20)) AS [Total Including VAT],
           CASE 
			WHEN orl.ModifiedDate > ord.ModifiedDate 
				THEN orl.ModifiedDate 
			ELSE ord.ModifiedDate END								AS [ModifiedDate]
    FROM 
		[HappyScoopers_Demo].[dbo].[Orders] ord
		LEFT JOIN [HappyScoopers_Demo].[dbo].[OrderLines] orl ON ord.OrderID = orl.OrderID
	    LEFT JOIN [HappyScoopers_Demo].[dbo].[Customers] cus ON ord.CustomerID = cus.CustomerID
		LEFT JOIN [HappyScoopers_Demo].[dbo].[Addresses] adr ON ord.DeliveryAddressID = adr.AddressID
		LEFT JOIN [HappyScoopers_Demo].[dbo].[Cities] cit ON adr.CityID = cit.CityID
		LEFT JOIN [HappyScoopers_Demo].[dbo].[Provinces] prv ON cit.ProvinceID = prv.ProvinceID
		LEFT JOIN [HappyScoopers_Demo].[dbo].[Countries] cou ON prv.CountryID = cou.CountryID
	    LEFT JOIN [HappyScoopers_Demo].[dbo].[Employees] emp ON ord.EmployeeID = emp.EmployeeID
        LEFT JOIN [HappyScoopers_Demo].[dbo].[PaymentTypes] pmt ON ord.PaymentTypeID = pmt.PaymentTypeID
		LEFT JOIN [HappyScoopers_Demo].[dbo].[Products] prd ON orl.ProductID = prd.ProductID
		LEFT JOIN [HappyScoopers_Demo].[dbo].[PackageTypes] pck ON orl.PackageTypeID = pck.PackageTypeID 
		LEFT JOIN [HappyScoopers_Demo].[dbo].[Promotions] pro ON orl.PromotionID = pro.PromotionID
WHERE 
	([ord].ModifiedDate > @LastLoadDate AND [ord].ModifiedDate <= @NewLoadDate) OR
	([orl].ModifiedDate > @LastLoadDate AND [orl].ModifiedDate <= @NewLoadDate) 


    RETURN 0;
END;



--Create or modify the procedure for loading data into the staging table 
Create procedure dbo.Load_stagingCustomer(@LastLoaddata datetime,@NewLoadData datetime)
as
begin
	set nocount on
	set xact_abort on 
select 
	'HSD|' + CONVERT(nvarchar,cus.CustomerID) _SourceKey,
	CONVERT(nvarchar(100),isnull(Cus.FirstName,'N/A')) First_Name,
	CONVERT(nvarchar(100),ISNULL(cus.[LastName], 'N/A'))[Last Name],
	CONVERT(nvarchar(200),ISNULL(cus.[FullName], 'N/A'))[Full Name],
	CONVERT(nvarchar(30), ISNULL(cus.[Title], 'N/A'))[Title], 
	CONCAT_WS('|','HSD',
		CONVERT(nvarchar(5), ISNULL(dcou.CountryID, 0)),
		CONVERT(nvarchar(5), ISNULL(dprv.ProvinceID, 0)),
		CONVERT(nvarchar(5), ISNULL(dcit.CityID, 0)), 
		CONVERT(nvarchar(5), ISNULL(dadr.AddressID, 0))) AS [Delivery Location Key],
	CONCAT_WS('|','HSD',
		CONVERT(nvarchar(5), ISNULL(bcou.CountryID, 0)),
		CONVERT(nvarchar(5), ISNULL(bprv.ProvinceID, 0)),
		CONVERT(nvarchar(5), ISNULL(bcit.CityID, 0)), 
		CONVERT(nvarchar(5), ISNULL(badr.AddressID, 0))) AS [Billing Location Key],
	CONVERT(nvarchar(24), ISNULL(cus.[PhoneNumber], 'N/A'))	[Phone Number], 
	CONVERT(nvarchar(100),ISNULL(cus.[Email], 'N/A')) [Email],
	CONVERT(datetime, ISNULL([cus].ModifiedDate, '1753-01-01'))	 [Customer Modified Date],
	CONVERT(datetime, ISNULL([dadr].ModifiedDate, '1753-01-01')) [Delivery Addr Modified Date],
	CONVERT(datetime, ISNULL([badr].ModifiedDate, '1753-01-01')) [Billing Addr Modified Date],
	(select MAX(t) from (values([cus].ModifiedDate),([badr].ModifiedDate),([dadr].ModifiedDate)) as ModifiedDate (t)),
	CONVERT(datetime,'9999-12-31')
from Customers Cus
	left join Addresses badr
		on Cus.BillingAddressID = badr.AddressID
	left join Cities bcit 
		on bcit.CityID = badr.CityID
	left join Provinces bprv
		on bprv.ProvinceID = bcit.ProvinceID
	left join Countries bcou
		on bcou.CountryID = bprv.CountryID

	left join Addresses dadr
		on dadr.AddressID = cus.DeliveryAddressID
	left join Cities dcit
		on dcit.CityID = dadr.CityID
	left join Provinces dprv
		on dprv.ProvinceID = dcit.ProvinceID
	left join Countries dcou
		on dcou.CountryID = dprv.CountryID
where
	(Cus.ModifiedDate > @LastLoaddata and Cus.ModifiedDate < @NewLoadData)
	or
	(badr.ModifiedDate > @LastLoaddata and badr.ModifiedDate < @NewLoadData )
	or
	(dadr.ModifiedDate > @LastLoaddata and dadr.ModifiedDate < @NewLoadData)
return 0 
end
Go
set ansi_nulls on 
go 
set quoted_identifier on 

--Create or modify procedure for loading data into the staging table 
create or alter procedure dbo.load_StagingEmployee (@LastLoadDate datetime,@NewLoadDate datetime)
as
begin
	set nocount on 
	set xact_abort on
	SELECT 
	 'HSD|' + CONVERT(NVARCHAR, emp.[EmployeeID])				AS [_SourceKey]
	,	CONCAT_WS('|', 'HSD', 
		CONVERT(nvarchar(5), ISNULL(cou.CountryID, 0)),
		CONVERT(nvarchar(5), ISNULL(prv.ProvinceID, 0)),
		CONVERT(nvarchar(5), ISNULL(cit.CityID, 0)), 
		CONVERT(nvarchar(5), ISNULL(adr.AddressID, 0)))			AS [Location Key]
	,CONVERT(nvarchar(100),emp.LastName)						AS [Last Name]
	,CONVERT(nvarchar(100),emp.FirstName)						AS [First Name]
	,CONVERT(nvarchar(25),emp.Title)							AS [Title]
	,CONVERT(date,emp.BirthDate)								AS [Birth Date]
	,CONVERT(nvarchar(10),emp.Gender)							AS [Gender]
	,CONVERT(date,emp.HireDate)									AS [Hire Date]
	,CONVERT(nvarchar(100),emp.JobTitle)						AS [Job Title]
	,CONVERT(nvarchar(100),adr.AddressLine1)					AS [Address Line]
	,CONVERT(nvarchar(100),cit.CityName)						AS [City]
	,CONVERT(nvarchar(100),cou.CountryName)						AS [Country]
	,'HSD|' + CONVERT(NVARCHAR, emp.ManagerID)					AS [Manager Key]
	,CONVERT(datetime, ISNULL(emp.ModifiedDate, '1753-01-01'))	AS [Employee Modified Date]
	,CONVERT(datetime, ISNULL(adr.ModifiedDate, '1753-01-01'))	AS [Address Modified Date]
	,(SELECT MAX(t) FROM
                             (VALUES
                               ([emp].ModifiedDate)
                             , ([adr].ModifiedDate)
                             ) AS [maxModifiedDate](t)
                           )								AS [ValidFrom]
	,CONVERT(datetime, '9999-12-31')						AS [ValidTo]
FROM [HappyScoopers_Demo].[dbo].[Employees] [emp]
LEFT JOIN [HappyScoopers_Demo].[dbo].[Addresses] [adr] ON emp.AddressID = adr.AddressID
LEFT JOIN [HappyScoopers_Demo].[dbo].Cities [cit] ON adr.CityID = cit.CityID
LEFT JOIN [HappyScoopers_Demo].[dbo].Provinces [prv] ON cit.ProvinceID = prv.ProvinceID
LEFT JOIN [HappyScoopers_Demo].[dbo].Countries [cou] ON prv.CountryID = cou.CountryID
WHERE 
	([emp].ModifiedDate > @LastLoadDate AND [emp].ModifiedDate <= @NewLoadDate) OR
	([adr].ModifiedDate > @LastLoadDate AND [adr].ModifiedDate <= @NewLoadDate) 

    RETURN 0;
END;

set ansi_nulls on
go
set quoted_identifier on 
go
-- Create or modify the procedure for loading data into the staging table
create  PROCEDURE [dbo].[Load_StagingLocation]
@LastLoadDate datetime,
@NewLoadDate datetime
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

--SELECT @LastLoadDate, @NewLoadDate

SELECT 
	CONCAT_WS('|', 'HSD', 
		CONVERT(nvarchar(5), ISNULL(cou.CountryID, 0)),
		CONVERT(nvarchar(5), ISNULL(prv.ProvinceID, 0)),
		CONVERT(nvarchar(5), ISNULL(cit.CityID, 0)), 
		CONVERT(nvarchar(5), ISNULL(adr.AddressID, 0)))						AS [_SourceKey],
	CONVERT(nvarchar(200),ISNULL(cou.Continent, 'N/A'))						AS [Continent],
	CONVERT(nvarchar(200),ISNULL(cou.Region, 'N/A'))						AS [Region],
	CONVERT(nvarchar(200),ISNULL(cou.Subregion, 'N/A'))						AS [Subregion],
	CONVERT(nvarchar(200), ISNULL(cou.CountryCode, 'N/A'))					AS [Country Code], 
	CONVERT(nvarchar(200), ISNULL(cou.CountryName, 'N/A'))					AS [Country], 
	CONVERT(nvarchar(200),ISNULL(cou.FormalName, 'N/A'))					AS [Country Formal Name],
	ISNULL(CONVERT(bigint,cou.Population), -1)								AS [Country Population],
	CONVERT(nvarchar(200),ISNULL(prv.ProvinceCode, 'N/A'))					AS [Province Code],
	CONVERT(nvarchar(200),ISNULL(prv.ProvinceName, 'N/A'))					AS [Province],
	ISNULL(CONVERT(bigint,prv.Population), -1)								AS [Province Population],
	CONVERT(nvarchar(200),ISNULL(cit.CityName, 'N/A'))						AS [City],
	ISNULL(CONVERT(bigint,cit.Population), -1)								AS [City Population],
	CONVERT(nvarchar(200),ISNULL(adr.PostalCode, 'N/A'))					AS [Postal Code],
	CONVERT(nvarchar(200),ISNULL(adr.AddressLine1, 'N/A'))					AS [Address Line 1],
	CONVERT(nvarchar(200),ISNULL(adr.AddressLine2, 'N/A'))					AS [Address Line 2],
	CONVERT(datetime, ISNULL([adr].ModifiedDate, '1753-01-01'))				AS [Address Modified Date],
	CONVERT(datetime, ISNULL([cit].ModifiedDate, '1753-01-01'))				AS [City Modified Date],
	CONVERT(datetime, ISNULL([prv].ModifiedDate, '1753-01-01'))				AS [Province Modified Date],
	CONVERT(datetime, ISNULL([cou].ModifiedDate, '1753-01-01'))				AS [Country Modified Date],
	(SELECT MAX(t) FROM
                             (VALUES
								   ([adr].ModifiedDate)
								 , ([cit].ModifiedDate)
								 , ([prv].ModifiedDate)
								 , ([cou].ModifiedDate)
								 ) AS [maxModifiedDate](t)
                           )												AS [ValidFrom],
	CONVERT(datetime, '9999-12-31')											AS [ValidTo]
FROM	
	[HappyScoopers_Demo].[dbo].[Addresses] adr 
	FULL JOIN [HappyScoopers_Demo].[dbo].[Cities] cit on adr.CityID = cit.CityID
	FULL JOIN [HappyScoopers_Demo].[dbo].[Provinces] prv on cit.ProvinceID = prv.ProvinceID
	FULL JOIN [HappyScoopers_Demo].[dbo].[Countries] cou on prv.CountryID = cou.CountryID
WHERE 
	([adr].ModifiedDate > @LastLoadDate AND [adr].ModifiedDate <= @NewLoadDate) OR
	([cit].ModifiedDate > @LastLoadDate AND [cit].ModifiedDate <= @NewLoadDate) OR
	([prv].ModifiedDate > @LastLoadDate AND [prv].ModifiedDate <= @NewLoadDate) OR
	([cou].ModifiedDate > @LastLoadDate AND [cou].ModifiedDate <= @NewLoadDate) 


    RETURN 0;
END;


-- Create or modify the procedure for loading data into the staging table
create or alter procedure dbo.Load_StagingPaymentType(@LastLoadDate datetime,@NewLoadDate datetime)
as
begin
	set nocount on 
	set xact_abort on 
select 
	'HSD|' + CONVERT(nvarchar,PaymentTypeID) as _SourceKey,
	CONVERT(nvarchar(100),isnull(PaymentTypes.PaymentTypeName,'N/A')) AS [Payment Type Name],
	CONVERT(datetime, ISNULL(PaymentTypes.[ModifiedDate], '1753-01-01'))AS [ValidFrom],
	CONVERT(datetime,'9999-12-31')  AS [ValidTo]
from PaymentTypes
where
	ModifiedDate >@LastLoadDate and ModifiedDate < @NewLoadDate
return 0
end
Go


set ansi_nulls on 
go 
set quoted_identifier on 
go

-- Create or modify the procedure for loading data into the staging table
create procedure dbo.load_StagingProduct(@LastLoadDate datetime,@NewLoadDate datetime)
as
begin
	set nocount on 
	set xact_abort on
	select
	 'HSD|' + CONVERT(NVARCHAR, prod.[ProductID])			AS [_SourceKey]
	,CONVERT(nvarchar(200), prod.[ProductName])				AS [Product Name]
	,CONVERT(nvarchar(50), prod.[ProductCode])				AS [Product Code]
	,CONVERT(nvarchar(200), prod.[ProductDescription])		AS [Product Description]
	,CONVERT(nvarchar(200), subcat.[SubcategoryName])		AS [Subcategory]
	,CONVERT(nvarchar(200), cat.[CategoryName])				AS [Category]
	,CONVERT(nvarchar(200), dep.[Name])						AS [Department]
	,CONVERT(nvarchar(10), um.[UnitMeasureCode])			AS [Unit of measure Code]
	,CONVERT(nvarchar(50), um.[Name])						AS [Unit of measure Name]
	,CONVERT(decimal(18,2), prod.[UnitPrice])				AS [Unit Price]
	,CONVERT(nvarchar(10), CASE prod.[Discontinued]
		WHEN 1 THEN 'Yes'
		ELSE 'No'
	 END)													AS [Discontinued] 
	,CONVERT(datetime, ISNULL([prod].ModifiedDate, '1753-01-01'))	AS [Product Modified Date]
	,CONVERT(datetime, ISNULL([subcat].ModifiedDate, '1753-01-01'))	AS [Subcategory Modified Date]
	,CONVERT(datetime, ISNULL([cat].ModifiedDate, '1753-01-01'))	AS [Category Modified Date]
	,CONVERT(datetime, ISNULL([dep].ModifiedDate, '1753-01-01'))	AS [Department Modified Date]
	,CONVERT(datetime, ISNULL([um].ModifiedDate, '1753-01-01'))		AS [UM Modified Date]
	,(SELECT MAX(t) FROM
                             (VALUES
                               ([prod].ModifiedDate)
                             , ([subcat].ModifiedDate)
                             , ([cat].ModifiedDate)
                             , ([dep].ModifiedDate)
                             , ([um].ModifiedDate)
                             ) AS [maxModifiedDate](t)
                           )								AS [ValidFrom]
	,CONVERT(datetime, '9999-12-31')						AS [ValidTo]

FROM [HappyScoopers_Demo].[dbo].[Products] prod
LEFT JOIN [HappyScoopers_Demo].[dbo].[ProductSubcategories] subcat ON prod.SubcategoryID = subcat.ProductSubcategoryID
LEFT JOIN [HappyScoopers_Demo].[dbo].[ProductCategories] cat ON subcat.ProductCategoryID = cat.CategoryID
LEFT JOIN [HappyScoopers_Demo].[dbo].[ProductDepartments] dep ON cat.DepartmentID = dep.DepartmentID
LEFT JOIN [HappyScoopers_Demo].[dbo].[UnitsOfMeasure] um ON prod.UnitOfMeasureID = um.UnitOfMeasureID

WHERE 
	([prod].ModifiedDate > @LastLoadDate AND [prod].ModifiedDate <= @NewLoadDate) OR
	([subcat].ModifiedDate > @LastLoadDate AND [subcat].ModifiedDate <= @NewLoadDate) OR
	([cat].ModifiedDate > @LastLoadDate AND [cat].ModifiedDate <= @NewLoadDate) OR
	([dep].ModifiedDate > @LastLoadDate AND [dep].ModifiedDate <= @NewLoadDate) OR
	([um].ModifiedDate > @LastLoadDate AND [um].ModifiedDate <= @NewLoadDate)

RETURN 0;
END;

create  PROCEDURE [dbo].[Load_StagingPromotion]
@LastLoadDate datetime,
@NewLoadDate datetime
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

--SELECT @LastLoadDate, @NewLoadDate

SELECT 
	 'HSD|' + CONVERT(NVARCHAR, pro.[PromotionID])					AS [_SourceKey],
	CONVERT(nvarchar(100),ISNULL(pro.[DealDescription], 'N/A'))		AS [Deal Description],
	CONVERT(date,ISNULL(pro.[StartDate], '1753-01-01'))				AS [Start Date],
	CONVERT(date,ISNULL(pro.[EndDate], '1753-01-01'))				AS [End Date],
	CONVERT(decimal(18,2), ISNULL(pro.[DiscountAmount], 0))			AS [Discount Amount], 
	CONVERT(decimal(18,3), ISNULL(pro.[DiscountPercentage], 0))		AS [Discount Percentage], 
	CONVERT(datetime, ISNULL(pro.[ModifiedDate], '1753-01-01'))		AS [Promotion Modified Date],
	CONVERT(datetime, ISNULL(pro.[ModifiedDate], '1753-01-01'))		AS [ValidFrom],
	CONVERT(datetime, '9999-12-31')									AS [ValidTo]
FROM	
	[HappyScoopers_Demo].[dbo].[Promotions] pro

WHERE 
	([pro].ModifiedDate > @LastLoadDate AND [pro].ModifiedDate <= @NewLoadDate) 

    RETURN 0;
END;
GO

CREATE PROCEDURE [dbo].[Load_StagingSales]
@LastLoadDate datetime,
@NewLoadDate datetime
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SELECT CAST(ord.OrderDate AS date)								AS [_SourceOrderDateKey],
           CAST(ord.DeliveryDate AS date)							AS [_SourceDeliveryDateKey],
           ord.OrderID												AS [_SourceOrder],
		   ISNULL(orl.OrderLineID, 0)								AS [_SourceOrderLine],
		   cus.CustomerID											AS [_SourceCustomerKey],
		   emp.EmployeeID											AS [_SourceEmployeeKey],
		   prd.ProductID											AS [_SourceProductKey],
		   pmt.PaymentTypeID										AS [_SourcePaymentTypeKey],
		   cou.CountryID											AS [_SourceDeliveryCountryKey],
		   prv.ProvinceID											AS [_SourceDeliveryProvinceKey],
		   cit.CityID												AS [_SourceDeliveryCityKey],
		   adr.AddressID											AS [_SourceDeliveryAddressKey],
		   CONCAT_WS('|', cou.CountryID, 
			prv.ProvinceID,
			cit.CityID,
			adr.AddressID)											AS [_SourceDeliveryLocationKey],
		   pro.PromotionID											AS [_SourcePromotionKey],
		   ISNULL(orl.Description, 'N/A)')							AS [Description],
           ISNULL(pck.PackageTypeName, 'N/A')						AS [Package],
           orl.Quantity												AS [Quantity],
           orl.UnitPrice											AS [Unit Price],
           ISNULL(orl.VATRate, 0.20)								AS [VAT Rate],
           orl.Quantity * orl.UnitPrice								AS [Total Excluding VAT],
		   orl.Quantity * orl.UnitPrice * ISNULL(orl.VATRate, 0.20) AS [VAT Amount],
		   orl.Quantity*orl.UnitPrice*(1+ ISNULL(orl.VATRate, 0.20)) AS [Total Including VAT],
           CASE 
			WHEN orl.ModifiedDate > ord.ModifiedDate 
				THEN orl.ModifiedDate 
			ELSE ord.ModifiedDate END								AS [ModifiedDate]
    FROM 
		[HappyScoopers_Demo].[dbo].[Orders] ord
		LEFT JOIN [HappyScoopers_Demo].[dbo].[OrderLines] orl ON ord.OrderID = orl.OrderID
	    LEFT JOIN [HappyScoopers_Demo].[dbo].[Customers] cus ON ord.CustomerID = cus.CustomerID
		LEFT JOIN [HappyScoopers_Demo].[dbo].[Addresses] adr ON ord.DeliveryAddressID = adr.AddressID
		LEFT JOIN [HappyScoopers_Demo].[dbo].[Cities] cit ON adr.CityID = cit.CityID
		LEFT JOIN [HappyScoopers_Demo].[dbo].[Provinces] prv ON cit.ProvinceID = prv.ProvinceID
		LEFT JOIN [HappyScoopers_Demo].[dbo].[Countries] cou ON prv.CountryID = cou.CountryID
	    LEFT JOIN [HappyScoopers_Demo].[dbo].[Employees] emp ON ord.EmployeeID = emp.EmployeeID
        LEFT JOIN [HappyScoopers_Demo].[dbo].[PaymentTypes] pmt ON ord.PaymentTypeID = pmt.PaymentTypeID
		LEFT JOIN [HappyScoopers_Demo].[dbo].[Products] prd ON orl.ProductID = prd.ProductID
		LEFT JOIN [HappyScoopers_Demo].[dbo].[PackageTypes] pck ON orl.PackageTypeID = pck.PackageTypeID 
		LEFT JOIN [HappyScoopers_Demo].[dbo].[Promotions] pro ON orl.PromotionID = pro.PromotionID
WHERE 
	([ord].ModifiedDate > @LastLoadDate AND [ord].ModifiedDate <= @NewLoadDate) OR
	([orl].ModifiedDate > @LastLoadDate AND [orl].ModifiedDate <= @NewLoadDate) 

    RETURN 0;
END;

















































	


