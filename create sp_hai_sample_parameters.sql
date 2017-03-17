USE [equis]
GO
/****** Object:  StoredProcedure [HAI].[sp_HAI_sample_parameters]    Script Date: 2/28/2017 4:13:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*Creates a table of Sample Parameters. 
		-Set up to be appended to Get EQuIS Data.
		-Requires sp_hai_get_locs to run and create ##locs*/

alter procedure  [HAI].[sp_HAI_sample_parameters] 
(

	     @facility_id int 
		,@sample_type varchar(200)
		,@task_codes varchar (1000)
		,@start_date datetime --= 'jan 01 1900 12:00 AM',
		,@end_date datetime -- ='dec 31 2050 11:59 PM',
		,@matrix_codes varchar (500)
		,@sample_param_codes varchar (4000)
	)

as
begin

	if object_id ('tempdb..##sample_parameters') is not null drop table ##sample_parameters
	create table ##sample_parameters(
			facility_id int
			,subfacility_name varchar (100)
			,sys_sample_code varchar (40)
			,sample_id int
			,sample_name varchar (40)
			,sample_type_code varchar (10)
			,sys_loc_code varchar (20)
			,task_code  varchar(40)
			,sample_source varchar (20)
			,sample_datetime datetime
			,sample_date varchar (20)
			,sample_date_range varchar (30)
			,sample_end_datetime datetime
			,matrix_code varchar (10)
			,analytic_method varchar (20)
			,measurment_date varchar (20)
			,parameter_group_name varchar(40)
			,param_code varchar (255)
			,cas_rn varchar (20)
			,param_value varchar (20)
			,param_unit varchar (10)
			)

	insert into ##sample_parameters
	select distinct 
		s.facility_id as facility_id
		,sf.subfacility_name as subfacility_name
		, coalesce(s.sample_name,s.sys_sample_code) as sys_sample_code
		,s.sample_id
		, s.sample_name
		, s.sample_type_code
		, s.sys_loc_code
		, s.task_code 
		, s.sample_source
		,s.sample_date as sample_datetime
		, convert(varchar,s.sample_date,101)  as sample_date
		,'12/31/2015 - 12/31/2015' as sample_date_range
		,cast([rpt].[fn_HAI_sample_end_date] (duration,duration_unit,sample_date) as datetime) as sample_end_datetime
		,s.matrix_code
		,'Sample Parameters'
		,isnull(measurement_method, 'Sample Parameter') as analytic_method
		,measurement_date
		,sp.param_code as param_code
		,left(sp.param_code,15) as cas_rn
		,sp.param_value 
		,sp.param_unit 
		
		from dt_sample s 
			inner join dt_location loc on s.facility_id = loc.facility_id and s.sys_loc_code = loc.sys_loc_code
			inner join ##locs l on s.facility_id = l.facility_id and s.sys_loc_code = l.sys_loc_code
			left join dt_subfacility sf on loc.subfacility_code = sf.subfacility_code
			inner join dt_sample_parameter sp on s.facility_id = sp.facility_id and s.sys_sample_code = sp.sys_sample_code
			inner join rt_sample_param_type rspt on sp.param_code = rspt.param_code

		where s.facility_id =@facility_id  
			and s.matrix_code in (select matrix_code from rpt.fn_hai_get_matrix(@facility_id, @matrix_codes))
			and coalesce(s.task_code, 'none') in (select task_code from rpt.fn_hai_get_taskcode(@facility_id, @task_codes))
			and (cast(s.sample_date as datetime)>= @start_date and cast(s.sample_date as datetime) <= @end_date + 1)
			and sp.param_code in (select cast(value as varchar (100)) from dbo.fn_split(@sample_param_codes))	


		declare @sample_params_list table(sample_params_name varchar(100) primary key)
		
		insert into @sample_params_list
		select distinct param_code  from ##sample_parameters


/*Build the sample parameters xtab target table*/
		if object_id('tempdb..##sample_params_xtab') is not null drop table ##sample_params_xtab
		declare @param_name varchar (100)
		declare @SQL_sp varchar (max) ='create table ##sample_params_xtab (facility_id1 int, sys_sample_code1 varchar(50),' + char(13)

		
		while (select count(*) from @sample_params_list) >0
		begin
			set @param_name = (select top 1 sample_params_name from @sample_params_list)
	
			set @SQL_sp = @SQL_sp +'[' + @param_name + '] varchar(100),' + char(13) + '[' + @param_name + '_unit] varchar(10),' + char(13)

			
			delete @sample_params_list where sample_params_name = @param_name
		end

/*Insert sample parameters into xtab target table*/
		insert into @sample_params_list
		select distinct param_code  from ##sample_parameters	
			
		set @SQL_sp = left(@SQL_sp,len(@SQL_sp) -2) + ')'

		exec (@SQL_sp)

		raiserror('insert to xtab' ,0,1) with nowait	

		set @SQL_sp = 'insert into ##sample_params_xtab ' + char(13) +
		'select ' + char(13) +
		'facility_id ' + char(13) +
		',sys_sample_code ' + char(13)

		while (select count(*) from @sample_params_list) >0
		begin
			set @param_name = (select top 1 sample_params_name from @sample_params_list)

			set @SQL_sp = @SQL_sp +
			',max(case when param_code = ' + '''' +  @param_name  + '''' + ' then param_value end)' + char(13) +
			',max(case when param_code = ' + '''' + @param_name  + '''' + ' then param_unit end)' + char(13)

			delete @sample_params_list where sample_params_name = @param_name
		end
			set @SQL_sp = @SQL_sp +
			'from ##sample_parameters ' + char(13) +
			'group by facility_id, sys_sample_code'

			exec( @SQL_sp)
		 select * from ##sample_params_xtab
end