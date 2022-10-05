Create table IncrementalLoads(
	LoadDateKey int identity(1,1) primary key not null,
	TableName nvarchar(100) not null,
	LoadDate datetime not null
	) on [Primary]

	Create table Lineage(
	LineageKey int identity(1,1) primary key not null,
	TableName nvarchar(100),
	[StartLoad] [datetime] NOT NULL,
	[FinishLoad] [datetime] NULL,
	[LastLoadedDate] [datetime] NOT NULL,
	[Status] [nvarchar](1) NOT NULL,
	[Type] [nvarchar](1) NOT NULL
	) on [Primary]
	
	alter table dbo.lineage add constraint [DF_Lineage_Status] Default (N'P') for [Status]
	alter table dbo.lineage add constraint [DF_Lineage_Status] Default (N'P') for [Status]