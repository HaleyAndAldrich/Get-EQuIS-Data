
	declare @facility_id int
	declare @location_groups varchar (2000)
	declare @locations varchar (2000)
	declare @sample_type varchar(200)
	declare @task_codes varchar (1000)
	declare @SDG varchar (2000)
	declare @start_date datetime --= 'jan 01 1900 12:00 AM'
	declare @end_date datetime
	declare @analyte_groups varchar(2000)
	declare @cas_rns varchar (2000)
	declare @matrix_codes varchar (500)
	declare @target_unit varchar(100)
	declare @limit_type varchar (10) 
	declare @action_level_codes varchar (500)
	declare @loc_param_codes varchar(2000) 
	declare @sample_params varchar(10) 
	declare @user_qual_def varchar (10)
	declare @show_val_yn varchar(10) 
	declare @coord_type varchar (20)
	declare @detects_only varchar (10) 
	

declare @report_run_id int = (select max(report_run_id) from hai.report_logging)
declare @parameter_id int = 1
declare @report_id_cnt as  int = @report_run_id
declare @parameter_id_cnt as int = (select max(parameter_id) from hai.report_logging)

declare @sql1 varchar (max)



	--while @id_cnt > 0
	while @parameter_id <= @parameter_id_cnt
	begin


	
		set @facility_id = (select  parameter_value  from hai.report_logging where report_run_id = 1 and parameter_id =  1)
		set @location_groups = (select  parameter_value  from hai.report_logging where report_run_id = 1 and parameter_id =  2)
		set @locations = (select  parameter_value  from hai.report_logging where report_run_id = 1 and parameter_id =  3)
		set @sample_type = (select  parameter_value  from hai.report_logging where report_run_id = 1 and parameter_id =  4)
		set @task_codes = (select  parameter_value  from hai.report_logging where report_run_id = 1 and parameter_id =  5)
		set @SDG = (select  parameter_value  from hai.report_logging where report_run_id = 1 and parameter_id =  6)
		set @start_date = (select  parameter_value  from hai.report_logging where report_run_id = 1 and parameter_id =  7)
		set @end_date = (select  parameter_value  from hai.report_logging where report_run_id = 1 and parameter_id =  8)
		set @analyte_groups = (select  parameter_value  from hai.report_logging where report_run_id = 1 and parameter_id =  9)
		set @cas_rns = (select  parameter_value  from hai.report_logging where report_run_id = 1 and parameter_id =  10)
		set @matrix_codes = (select  parameter_value  from hai.report_logging where report_run_id = 1 and parameter_id =  11)
		set @target_unit = (select  parameter_value  from hai.report_logging where report_run_id = 1 and parameter_id =  12)
		set @limit_type = (select  parameter_value  from hai.report_logging where report_run_id = 1 and parameter_id =  13)
		set @action_level_codes = (select  parameter_value  from hai.report_logging where report_run_id = 1 and parameter_id =  14)
		set @loc_param_codes = (select  parameter_value  from hai.report_logging where report_run_id = 1 and parameter_id =  15)
		set @sample_params = (select  parameter_value  from hai.report_logging where report_run_id = 1 and parameter_id =  16)
		set @user_qual_def = (select  parameter_value  from hai.report_logging where report_run_id = 1 and parameter_id =  17)
		set @show_val_yn = (select  parameter_value  from hai.report_logging where report_run_id = 1 and parameter_id =  18)
		set @coord_type = (select  parameter_value  from hai.report_logging where report_run_id = 1 and parameter_id =  19)
		set @detects_only = (select  parameter_value  from hai.report_logging where report_run_id = 1 and parameter_id = 20)





		set @parameter_id = @parameter_id + 1
		--print cast(@parameter_id as varchar ) 

		


	end

	exec   [hai].[sp_Get_EQuIS_Results_w_ALs_test]
	  @facility_id 
	,  @location_groups 
	,  @locations 
	,  @sample_type 
	,  @task_codes 
	,  @SDG 
	,  @start_date  --= 'jan 01 1900 12:00 AM'
	,  @end_date 
	,  @analyte_groups 
	,  @cas_rns 
	,  @matrix_codes  
	,  @target_unit 
	,  @limit_type  
	,  @action_level_codes  
	,  @loc_param_codes  
	,  @sample_params 
	,  @user_qual_def  
	,  @show_val_yn 
	,  @coord_type  
	,  @detects_only  

	