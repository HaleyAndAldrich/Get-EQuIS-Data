USE [equis]
GO

/****** Object:  Table [HAI].[report_logging]    Script Date: 1/17/2017 10:28:56 AM ******/
DROP TABLE [HAI].[report_logging]
GO

/****** Object:  Table [HAI].[report_logging]    Script Date: 1/17/2017 10:28:56 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [HAI].[report_logging](
	[report_run_id] [int] NULL,
	[report_id] [varchar](20) NULL,
	[report_name] [varchar](200) NULL,
	[parameter_id] [int] NULL,
	[parameter_name] [varchar](200) NULL,
	[parameter_value] [varchar](2000) NULL,
	[report_date] [varchar](100) NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


