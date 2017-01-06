use equis
go

exec rpt.sp_hai_get_locs 47, null, 'p39-eb-08'

exec [hai].[sp_HAI_sample_parameters] 
		47
 		,'n' --@sample_type varchar(200)
		,'PGE-P39-EB' --@task_codes varchar (1000)
		,'1/1/1900' --@start_date datetime --= 'jan 01 1900 12:00 AM',
		,'1/1/2050' --@end_date datetime -- ='dec 31 2050 11:59 PM',
		,'se' --@matrix_codes varchar (500)
		,'Elevation Range|Mudline Elevation' --@sample_param_codes varchar (4000)


