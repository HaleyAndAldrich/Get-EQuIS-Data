use equis
go



if object_id ('tempdb..##locs') is not null drop table ##locs

exec rpt.sp_hai_get_locs 1686992, null, null --'IA-18-1-BR|AA-NE'

exec [hai].[sp_HAI_sample_parameters] 
		1686992
 		,'n' --@sample_type varchar(200)
		,null --@task_codes varchar (1000)
		,'320305271|320307471'
		,'1/1/1900' --@start_date datetime --= 'jan 01 1900 12:00 AM',
		,'1/1/2050' --@end_date datetime -- ='dec 31 2050 11:59 PM',
		,null --@matrix_codes varchar (500)
		,'date range' --@sample_param_codes varchar (4000)


	
