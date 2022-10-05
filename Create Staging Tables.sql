create table dbo.Stagging_Sales(
		[Stagging Sale Key] bigint identity(1,1),
		[Customer Key] int null,
		[Employee Key] int null,
		[Payment Type Key] int null,
		[Order Date Key] int null,
		[Delivery Date Key] int null,
		[Delivery Location Key] int null,
		[Promotion Key] int null,

		--degenerate dimensions
		[Description] nvarchar(100) null  ,[Package] nvarchar(50) null , 
		
		--Facts
		[Quantity] int null, 
		[Unit Price] decimal(18,2) null,
		[VAT Rate] decimal(18,3) null,
		[Total Excluding VAT] decimal(18,2) null,
		[VAT amount] decimal(18,2) null,
		[Total Including VAT] decimal(18,2) null,

	[ModifiedDate] [datetime] NULL,
	[_SourceOrder] [nvarchar](50) NULL,
	[_SourceOrderLine] [nvarchar](50) NULL,
	[_SourceCustomerKey] [int] NULL,
	[_SourceEmployeeKey] [int] NULL,
	[_SourceProductKey] [int] NULL,
	[_SourcePaymentTypeKey] [int] NULL,
	[_SourceOrderDateKey] [date] NULL,
	[_SourceDeliveryDateKey] [date] NULL,
	[_SourceDeliveryCountryKey] [int] NULL,
	[_SourceDeliveryProvinceKey] [int] NULL,
	[_SourceDeliveryCityKey] [int] NULL,
	[_SourceDeliveryAddressKey] [int] NULL,
	[_SourceDeliveryLocationKey] [nvarchar](50) NULL,
	[_SourcePromotionKey] [int] NULL
) ON [PRIMARY]

	CREATE TABLE [dbo].[Staging_Promotion](
	[Promotion Key] [int] IDENTITY(1,1) NOT NULL,
	[_Source Key] [nvarchar](50) NOT NULL,
	[Deal Description] [nvarchar](30) NOT NULL,
	[Start Date] [date] NOT NULL,
	[End Date] [date] NOT NULL,
	[Discount Amount] [decimal](18, 2) NULL,
	[Discount Percentage] [decimal](18, 3) NULL,
	[Modified Date] [datetime] NOT NULL,
	[Valid From] [datetime] NOT NULL,
	[Valid To] [datetime] NOT NULL
) ON [PRIMARY]

CREATE TABLE [dbo].[Staging_Product](
	[Product Key] [int] IDENTITY(1,1) NOT NULL,
	[_Source Key] [nvarchar](50) NOT NULL,
	[Product Name] [nvarchar](200) NOT NULL,
	[Product Code] [nvarchar](50) NOT NULL,
	[Product Description] [nvarchar](200) NOT NULL,
	[Product Subcategory] [nvarchar](200) NOT NULL,
	[Product Category] [nvarchar](200) NOT NULL,
	[Product Department] [nvarchar](200) NOT NULL,
	[Unit Of Measure Code] [nvarchar](10) NOT NULL,
	[Unit Of Measure Name] [nvarchar](50) NOT NULL,
	[Unit Price] [decimal](18, 2) NOT NULL,
	[Discontinued] [nvarchar](10) NOT NULL,
	[Product Modified Date] [datetime] NOT NULL,
	[Subcategory Modified Date] [datetime] NOT NULL,
	[Category Modified Date] [datetime] NOT NULL,
	[Department Modified Date] [datetime] NOT NULL,
	[UM Modified Date] [datetime] NOT NULL,
	[Valid From] [datetime] NOT NULL,
	[Valid To] [datetime] NOT NULL
) ON [PRIMARY]
GO

	CREATE TABLE [dbo].[Staging_PaymentType](
	[Payment Type Key] [int] IDENTITY(1,1) NOT NULL,
	[_Source Key] [nvarchar](50) NOT NULL,
	[Payment Type Name] [nvarchar](50) NOT NULL,
	[Valid From] [datetime] NOT NULL,
	[Valid To] [datetime] NOT NULL
) ON [PRIMARY]

	
	CREATE TABLE [dbo].[Staging_Location](
	[Location Key] [int] IDENTITY(1,1) NOT NULL,
	[_Source Key] [nvarchar](200) NOT NULL,
	[Continent] [nvarchar](200) NOT NULL,
	[Region] [nvarchar](200) NOT NULL,
	[Subregion] [nvarchar](200) NOT NULL,
	[Country Code] [nvarchar](200) NULL,
	[Country] [nvarchar](200) NOT NULL,
	[Country Formal Name] [nvarchar](200) NOT NULL,
	[Country Population] [bigint] NULL,
	[Province Code] [nvarchar](200) NOT NULL,
	[Province] [nvarchar](200) NOT NULL,
	[Province Population] [bigint] NULL,
	[City] [nvarchar](200) NOT NULL,
	[City Population] [bigint] NULL,
	[Address Line 1] [nvarchar](200) NOT NULL,
	[Address Line 2] [nvarchar](200) NULL,
	[Postal Code] [nvarchar](200) NOT NULL,
	[Address Modified Date] [datetime] NOT NULL,
	[City Modified Date] [datetime] NOT NULL,
	[Province Modified Date] [datetime] NOT NULL,
	[Country Modified Date] [datetime] NOT NULL,
	[Valid From] [datetime] NOT NULL,
	[Valid To] [datetime] NOT NULL
) ON [PRIMARY]
GO
	CREATE TABLE [dbo].[Staging_Employee](
	[Employee Key] [int] IDENTITY(1,1) NOT NULL,
	[_Source Key] [nvarchar](50) NOT NULL,
	[Location Key] [nvarchar](50) NOT NULL,
	[Last Name] [nvarchar](100) NOT NULL,
	[First Name] [nvarchar](100) NOT NULL,
	[Title] [nvarchar](30) NOT NULL,
	[Birth Date] [datetime] NOT NULL,
	[Gender] [nchar](10) NOT NULL,
	[Hire Date] [datetime] NOT NULL,
	[Job Title] [nvarchar](100) NOT NULL,
	[Address Line] [nvarchar](100) NULL,
	[City] [nvarchar](100) NULL,
	[Country] [nvarchar](100) NULL,
	[Manager Key] [nvarchar](50) NULL,
	[Employee Modified Date] [datetime] NOT NULL,
	[Addresses Modified Date] [datetime] NOT NULL,
	[Valid From] [datetime] NOT NULL,
	[Valid To] [datetime] NOT NULL
) ON [PRIMARY]

	CREATE TABLE [dbo].[Staging_Customer](
	[Customer Key] [int] IDENTITY(1,1) NOT NULL,
	[_Source Key] [nvarchar](50) NOT NULL,
	[First Name] [nvarchar](100) NOT NULL,
	[Last Name] [nvarchar](100) NOT NULL,
	[Full Name] [nvarchar](50) NOT NULL,
	[Title] [nvarchar](30) NOT NULL,
	[Delivery Location Key] [nvarchar](50) NOT NULL,
	[Billing Location Key] [nvarchar](50) NOT NULL,
	[Phone Number] [nvarchar](24) NOT NULL,
	[Email] [nvarchar](100) NULL,
	[Customer Modified Date] [datetime] NOT NULL,
	[Delivery Addr Modified Date] [datetime] NOT NULL,
	[Billing Addr Modified Date] [datetime] NOT NULL,
	[Valid From] [datetime] NOT NULL,
	[Valid To] [datetime] NOT NULL
) ON [PRIMARY]
