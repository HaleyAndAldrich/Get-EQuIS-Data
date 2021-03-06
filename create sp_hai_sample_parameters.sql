

use equis
go

set nocount on
go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


alter procedure hai.sp_hai_sample_parameters(
	 @facility_id int 
 	,@sample_type varchar(200) 
	,@task_codes varchar (1000) 
	,@start_date datetime 
	,@end_date datetime 
	,@matrix_codes varchar (500)	
	,@sample_param_codes varchar (4000)
	)

	as
	begin  
	select distinct 
		s.facility_id as facility_id		
		,sf.subfacility_name as subfacility_name
		, s.sys_sample_code as sys_sample_code
		, s.sample_name
		, s.sample_type_code
		, s.sys_loc_code
		, s.task_code 
		, s.sample_source
		,s.sample_date as sample_datetime
		, convert(varchar,s.sample_date,101)  as sample_date
		,'12/31/2015 - 12/31/2015' as sample_date_range
		,cast([rpt].[fn_HAI_sample_end_date] (coalesce(duration,'0'),coalesce(duration_unit,'hrs'),sample_date) as datetime) as sample_end_datetime
		,coalesce(rspt.param_desc, sp.param_code) as chemical_name
		,param_value as result_qualifier
		,param_value as report_result
		,param_unit as result_unit
		,isnull(measurement_method, 'Sample Parameter') as analytic_method
		,'Sample Parameters' as compound_group
		,'Sample Parameters' as param_group_name
		,left(sp.param_code,15) as cas_rn
		,case when param_value = 'NM' or param_value = '--' then 'N' else 'Y' end as detect_flag 
		,case when param_value = 'NM' or param_value = '--' then '<' else null end as nd_flag 
		,'99' as mag_report_order
		,'99' as param_group_order
		
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


	end