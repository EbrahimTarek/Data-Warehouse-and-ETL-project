use HappyScoopers_DW
Go
set ansi_nulls on 
Go
set quoted_identifier on
GO
create table dbo.[Dim_Customer](
	[Customer key] int identity(1,1) not null,
	[_Source Key] [nvarchar](50) NOT NULL,
	[First Name] [nvarchar](100) NOT NULL,
	[Last Name] [nvarchar](100) NOT NULL,
	[Full Name]  AS (([First Name]+' ')+[Last Name]),
	[Title] [nvarchar](30) NOT NULL,
	[Delivery Location Key] [nvarchar](50) NOT NULL,
	[Billing Location Key] [nvarchar](50) NOT NULL,
	[Phone Number] [nvarchar](24) NOT NULL,
	[Email] [nvarchar](100) NULL,
	[Valid From] [datetime] NOT NULL,
	[Valid To] [datetime] NOT NULL,
	[Lineage Key] [int] NOT NULL,
	constraint PK_Dim_Customer primary key clustered ( [Customer key] asc ) 
	)
	on [primary]


Create table dbo.[Dim_Date](
	[Date Key] [int] NOT NULL,
	[Date] [date] NOT NULL,
	[Day] [tinyint] NOT NULL,
	[Day Suffix] char(2) NOT NULL,

	[weekday] tinyint Not Null,
	[Weekday Name] [varchar](10) NOT NULL,
	[Weekday Name Short] [char](3) NOT NULL,
	[Weekday Name FirstLetter] [char](1) NOT NULL,

	[Day Of Year] [smallint] NOT NULL,
	[Week Of Month] [tinyint] NOT NULL,
	[Week Of Year] [tinyint] NOT NULL,

	[Month] [tinyint] NOT NULL,
	[Month Name] [varchar](10) NOT NULL,
	[Month Name Short] [char](3) NOT NULL,
	[Month Name FirstLetter] [char](1) NOT NULL,

	[Quarter] [tinyint] NOT NULL,
	[Quarter Name] [varchar](6) NOT NULL,
	[Year] [int] NOT NULL,
	[MMYYYY] [char](6) NOT NULL,
	[Month Year] [char](7) NOT NULL,

		[Is Weekend] [bit] NOT NULL,
	[Is Holiday] [bit] NOT NULL,
	[Holiday Name] [varchar](20) NOT NULL,
	[Special Day] [varchar](20) NOT NULL,

	[First Date Of Year] [date] NULL,
	[Last Date Of Year] [date] NULL,
	[First Date Of Quater] [date] NULL,
	[Last Date Of Quater] [date] NULL,
	[First Date Of Month] [date] NULL,
	[Last Date Of Month] [date] NULL,
	[First Date Of Week] [date] NULL,
	[Last Date Of Week] [date] NULL,

	[Lineage Key] [int] NULL,
primary key clustered ([Date key] asc)
)


alter table dim_date add default ((0)) for [Is Weekend]
alter table dim_date add default ((0)) for [Is Holiday]
alter table dim_date add default ('') for [Holiday Name]
alter table dim_date add default ('') for [Special Day]


create table dbo.[Dim_employee](
	[Employee Key] [int] IDENTITY(1,1) primary key NOT NULL,
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
	[Valid From] [datetime] NOT NULL,
	[Valid To] [datetime] NOT NULL,
	[Lineage Key] [int] NOT NULL
	)
	on [Primary]


create table dbo.[Dim_location](
	[Location Key] [int] IDENTITY(1,1) primary key NOT NULL,
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
	[Valid From] [datetime] NOT NULL,
	[Valid To] [datetime] NOT NULL,
	[Lineage Key] [int] NOT NULL
	)

create table dbo.Dim_payment(
	[Payment Type Key] [int] IDENTITY(1,1) NOT NULL,
	[_Source Key] [nvarchar](50) NOT NULL,
	[Payment Type Name] [nvarchar](50) NOT NULL,
	[Valid From] [datetime] NOT NULL,
	[Valid To] [datetime] NOT NULL,
	[Lineage Key] [int] NOT NULL,
 CONSTRAINT [PK_Dim_PaymentType] PRIMARY KEY CLUSTERED 
(
	[Payment Type Key] ASC
)
) ON [PRIMARY]


create table dbo.Dim_Product(
	[Product Key] [int] IDENTITY(1,1) primary key NOT NULL,
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
	[Valid From] [datetime] NOT NULL,
	[Valid To] [datetime] NOT NULL,
	[Lineage Key] [int] NOT NULL
	)

create table dbo.[Dim_Promotion](
		[Promotion Key] [int] IDENTITY(1,1) primary key NOT NULL,
		[_Source Ket] nvarchar(50) not null,
		[Deal Description] [nvarchar](30) NOT NULL,
		[Start Date] [date] NOT NULL,
		[End Date] [date] NOT NULL,
		[Discount Amount] [decimal](18, 2) NULL,
		[Discount Percentage] [decimal](18, 3) NULL,
		[Valid From] [datetime] NOT NULL,
		[Valid To] [datetime] NOT NULL,
		[Lineage Key] [int] NOT NULL
		)

		create table dbo.[Fact_Sales](
		[Sale Key] bigint identity(1,1) not null,
		[Customer key] int not null,
		[Employee Key] int not null,
		[Product Key] int not null,
		[Payment Type Key] [int] NOT NULL,
		[Order Date Key] int not null,
		[Delivery Date Key] int not null,
		[Delvery Location Key] int not null,
		[Promotion Key] int not null,
		[Description] nvarchar(100) not null,
		[Package] nvarchar(50) not null,
		[Unit Price] decimal(18,2) null,
		[Quantity] int null,
		[Vat Rate] decimal(18,3) null,
		[Total Excluding Vat] decimal(18,2) null,
		[Vat Amount] decimal(18,2) null,
		[Total including Vat] decimal(18,2) null,
		[_SourceOrder] nvarchar(50) not null,
		[_SourceOrderLine] nvarchar(50) not null,
		[Lineage Key] [int] NOT NULL
		) on [primary]

		






