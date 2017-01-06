USE [equis]
GO
/****** Object:  StoredProcedure [rpt].[sp_Get_EQuIS_Results_w_ALs_test]    Script Date: 12/21/2016 5:30:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



	ALTER procedure  [rpt].[sp_Get_EQuIS_Results_w_ALs_test]
	(
		 @facility_id int,
		 @location_groups varchar (2000),
		 @locations varchar (2000),
		 @sample_type varchar(200),
		 @task_codes varchar (1000),
		 @SDG varchar (2000),
		 @start_date datetime, --= 'jan 01 1900 12:00 AM',
		 @end_date datetime,  -- ='dec 31 2050 11:59 PM',
		 @analyte_groups varchar(2000),
		 @cas_rns varchar (2000),
		 @matrix_codes varchar (500),
		 @target_unit varchar(100),
		 @limit_type varchar (10) = 'RL',
		 @action_level_codes varchar (500),
		 @loc_param_codes varchar(2000) ,
		 @include_loc_params varchar(10) = 'N',
		 @user_qual_def varchar (10),
		 @show_val_yn varchar(10) ,
		 @coord_type varchar (20),
		 @detects_only varchar (10) = 'N'  /*returns all samples/chemicals if any one sample had that chemcial detected*/
	)
	as 
	begin

	declare @params varchar(1000)
	SELECT @params =  ISNULL(@params,'') + chemical_name + '|' 
	from (
	select chemical_name from rt_analyte where cas_rn in (select cast(value as varchar) from fn_split(@cas_rns)))z

	set @params = left(@params,len(@params) -1)


	set nocount on

	--log usage
	declare @report_time varchar (20) = cast(getdate() as varchar)
	declare @report_run_id int 
	set @report_run_id = (select max(coalesce(report_run_id,0)) +1 from hai.report_logging)
	declare @report_id int = (select report_id from st_report where report_name = 'rpt.sp_Get_EQuIS_Results_w_ALs_test')
	declare @report_name varchar (200) = 'sp_Get_EQuIS_Results_w_ALs_test'
	
	insert into [hai].[report_logging]
	select @report_run_id, @report_id,@report_name,'facility_id', cast(@facility_id as varchar) ,@report_time
	Union select @report_run_id, @report_id,@report_name,'location_groups',@location_groups  ,@report_time
	Union select @report_run_id, @report_id,@report_name,'locations', @locations  ,@report_time
	Union select @report_run_id, @report_id,@report_name,'sample_type', @sample_type ,@report_time
	Union select @report_run_id, @report_id,@report_name,'task_codes', @task_codes  ,@report_time
	Union select @report_run_id, @report_id,@report_name,'SDG',@SDG  ,@report_time
	Union select @report_run_id, @report_id,@report_name,'start_date',cast(@start_date as varchar) ,@report_time
	Union select @report_run_id, @report_id,@report_name,'end_date',cast(@end_date as varchar) , @report_time
	Union select @report_run_id, @report_id,@report_name,'analyte_groups',@analyte_groups ,@report_time
	Union select @report_run_id, @report_id,@report_name,'param',@params  ,@report_time
	Union select @report_run_id, @report_id,@report_name,'matrix_codes',@matrix_codes  ,@report_time
	Union select @report_run_id, @report_id,@report_name,'target_unit',@target_unit ,@report_time
	Union select @report_run_id, @report_id,@report_name,'limit_type',@limit_type   ,@report_time
	Union select @report_run_id, @report_id,@report_name,'action_level_codes',@action_level_codes  ,@report_time
	Union select @report_run_id, @report_id,@report_name,'loc_param_codes',@loc_param_codes  ,@report_time
	Union select @report_run_id, @report_id,@report_name,'user_qual_def',@user_qual_def  ,@report_time
	Union select @report_run_id, @report_id,@report_name,'show_val_yn',@show_val_yn  ,@report_time
	Union select @report_run_id, @report_id,@report_name,'coord_type',@coord_type  ,@report_time
	Union select @report_run_id, @report_id,@report_name,'detects_only',@detects_only,@report_time



	--make the action level table first because we need it in place to join to 
	--in the next section where we select into ##R

	declare @start_time as datetime = getdate()
	declare @elapsed_time as datetime
	declare @total_time as datetime
	declare @time_msg as varchar (200)

	--make the action level table first because we need it in place to join to 
	--in the next section where we select into ##R

	IF OBJECT_ID('tempdb..##AL') IS NOT NULL drop table ##AL

		--if (select count(@action_level_codes)) > 0  /*commented out because the table needs to exist even with zero rows or the query below barfs*/
		begin
			EXEC [rpt].[sp_HAI_ActionLevel_xtab]
				 @facility_id,
				 @action_level_codes --'NJ_WG_HigherGW_maxPQL_GWQS|NJ_WS_FW_AA_2009'
		end


	
	begin try
		IF OBJECT_ID('tempdb..##r') IS NOT NULL drop table ##r
	end try
	begin catch
		select 'Cannot drop ##r'
	end catch



--Format date range parameters
	set @start_date = cast(CONVERT(varchar,@start_date,101)as DATE)
	set @end_date = CAST(convert(varchar, @end_date, 101) as date)

		set @elapsed_time = getdate() - @start_time
		set @time_msg = 'begin result time:' + convert(varchar,@elapsed_time,114) 
	    raiserror(@time_msg ,0,1) with nowait	




--create main results set
	exec [hai].[sp_HAI_EQuIS_Results] 
			 @facility_id 
			,@start_date
			,@end_date
			,@sample_type 
			,@matrix_codes 
			,@task_codes 
			,@location_groups 
			,@locations 
			,@sdg 
			,@analyte_groups 
			,@cas_rns 
			,@target_unit 
			,@limit_type 
			,@coord_type 


		set @elapsed_time = getdate() - @start_time
	print '##result time:' + convert(varchar,@elapsed_time,114) 

	exec [rpt].[sp_HAI_GetParams] @facility_id,@analyte_groups, @params --creates ##mthgrps
	--select * from ##mthgrps


	--select count(*) from ##results

	
--Here's where we get the main data set
	begin try
	raiserror( 'Begin inserting ##r',0,1) with nowait
	select 
		 r.facility_id
		,sys_sample_code
		,r.sample_name
		,r.lab_sample_id
		,r.field_sdg
		,r.lab_sdg
		,r.sys_loc_code
		,r.loc_name
		,r.loc_report_order
		,r.loc_group
		,r.subfacility_name
		,r.start_depth
		,r.end_depth
		,r.depth_unit
		,case 
			when r.start_depth is not null and r.end_depth is not null 
			  then  cast(hai.fn_hai_depth_zero(r.start_depth) as varchar) + '-' + coalesce(cast(hai.fn_hai_depth_zero(end_depth) as varchar),'') --+ ' (' + depth_unit + ')'
			when r.start_depth is not null and r.end_depth is null 
			  then cast(hai.fn_hai_depth_zero(r.start_depth) as varchar) --+ ' (' + depth_unit + ')'
			when r.start_depth is null and r.end_depth is not null 
			  then cast(hai.fn_hai_depth_zero(r.end_depth) as varchar) --+ ' (' + depth_unit + ')'	
		end as sample_depth
		,r.sample_source
		,r.sample_date as sample_datetime
		,convert(varchar,sample_date,101) as sample_date
		,cast([rpt].[fn_HAI_sample_end_date] (duration,duration_unit,sample_date) as datetime) as sample_end_datetime
		,'12/31/2015 - 12/31/2015' as sample_date_range --MAA 1/5/2016 changed from 1-1 so the field length would be long enough to accept updates
		,r.task_code
		,r.matrix_code
		,r.sample_type_code
		,r.parameter_group_name
		,case when len(r.param_report_order) =1 THEN '0' + r.param_report_order else coalesce(r.param_report_order,'99') end as param_group_order
		,coalesce(r.mag_report_order,'99') as mag_report_order
		,r.analytic_method
		,case 
			when r.fraction = 'D' then 'Dissolved'
			when r.fraction = 'T' then 'Total'
			when r.fraction = 'N' then 'NA'
		end as fraction
		,r.cas_rn
		,coalesce(r.mth_grp_parameter,r.chemical_name) as chemical_name
		,r.detect_flag
		,r.result_text
		,r.result_numeric
		,r.reporting_detection_limit
		,r.method_detection_limit
		,r.reported_result_unit as lab_reported_result_unit
		,rpt.fn_HAI_result_qualifier ( --Recalc unit conversion in case default units are specified in method analyte group
			hai.fn_thousands_separator(equis.significant_figures(equis.unit_conversion(r.converted_result,r.converted_result_unit,coalesce(@target_unit,r.default_units, r.converted_result_unit),default),equis.significant_figures_get(r.converted_result),default)), --orginal result
			case 
				when detect_flag = 'N' then '<' 
				when detect_flag = 'Y' and charindex(validator_qualifiers, 'U') >0 then '<'
				when detect_flag = 'Y' and charindex(interpreted_qualifiers, 'U') >0 then '<'
				else null 
			end,  --nd flag
			reporting_qualifier,  --qualifiers
			interpreted_qualifiers,
			@user_qual_def) --how the user wants the result to look
			+ case when @show_val_yn = 'Y'  and (validated_yn = 'N' or validated_yn is null) then '[nv]' else '' end 
			as Result_Qualifier
			--update report_result_unit with method analyte group default units
		,equis.significant_figures(equis.unit_conversion(r.converted_result,r.converted_result_unit,coalesce(@target_unit,r.default_units, r.converted_result_unit),default),equis.significant_figures_get(r.converted_result),default) as Report_Result
		,coalesce(@target_unit,r.default_units,converted_result_unit) as report_unit
		,r.qualifier 
		,r.detection_limit_type
		,r.interpreted_qualifiers
		,r.validator_qualifiers
		,r.validated_yn
		,case 
			when detect_flag = 'N' then '<' 
			when detect_flag = 'Y' and charindex(validator_qualifiers, 'U') >0 then '<'
			when detect_flag = 'Y' and charindex(interpreted_qualifiers, 'U') >0 then '<'
			else null 
		 end ND_flag
		,approval_a
		,coord_type_code
		,cast(x_coord as real) as x_coord
		,cast(y_coord as real) as y_coord
		,al.*

	into ##r 
	from  ##results r


	left join ##al al on r.cas_rn = al.al_param_code  --grab those action levels


	end try
	begin catch
		select 'Error inserting ##results  to ##R ' + char(13)
		+ error_message()
	end catch

		set @elapsed_time = getdate() - @start_time
		set @time_msg =  'insert #r time:' + convert(varchar,@elapsed_time,114) 
		raiserror(@time_msg	,0,1) with nowait

	end

	Print 'Ready to process location parameters'
	/*******************************************************/
	/*Add Location Parameters if selected by the user*/
	if (select len(@loc_param_codes)) is not null
		begin
		  begin try
			insert into ##r(
			 facility_id
			,subfacility_name
			,sys_sample_code
			,sample_name
			,sample_type_code
			,sys_loc_code
			,task_code
			,sample_source
			,sample_datetime
			,sample_date
			,sample_date_range
			,sample_end_datetime
			,chemical_name
			,result_qualifier
			,report_result
			,report_unit
			,analytic_method
			,parameter_group_name
			,cas_rn
			,detect_flag
			,nd_flag
			,mag_report_order
			,param_group_order)
			exec  [hai].[sp_HAI_location_parameters]  @facility_id, @location_groups, @locations, @sample_type, @task_codes, @start_date, @end_date, @matrix_codes, @loc_param_codes
			print 'Insert loc_params done'
			insert into hai.report_logging (report_run_id, report_id,parameter_value, report_date)
			values (@report_run_id, @report_id, 'Insert loc_params done', @report_time)
				
			end try
			begin catch
				print 'Insert loc_params failed'
				declare @msg varchar (max)
				set @msg = error_message()
				print @msg
				insert into hai.report_logging (report_run_id, report_id,parameter_value, report_date)
				values (@report_run_id, @report_id, 'Insert loc_params failed: ' + @msg, @report_time)
			end catch
	end



	/*Delete samples where no chemcials were detected*/
	if @detects_only = 'Y'
	begin
		delete ##r
		where cas_rn not in
			(select distinct cas_rn from ##r where detect_flag = 'Y')
	end

	--select * from ##r
	/*The script below converts the action level values in ##AL to
	to match the units in the result table ##R or the target unit if it exists*/

	begin try
	declare @AL_Unit table (col_name varchar(200))
	insert into @al_unit
	Select  c.name from tempdb.sys.columns c
	inner join (select object_id  ,name from tempdb.sys.tables where name = '##r')t  --Here is where we find the value and unit column names
	on c.object_id = t.object_id													--dynamically created in ##AL
	where c.name like '%al_value' or c.name like '%al_unit'
	end try
	begin catch
		print '@AL_Unit table insert failed'
	end catch

	/*Make a table of the value and unit column names*/
	declare @name varchar (200)
	declare @unit varchar (200)
	declare @SQL varchar(max) = 'update ##r ' + char(13)
	
	

	/*Create a script to loop the AL value names and update the values to match either @target_unit or the report_unit*/
	while (select count(*) from @al_unit) > 0
	
		begin
			set @name = (select top 1 col_name from @AL_unit where right(col_name,5) = 'value')
			--print 'AL unit Name1- ' + @name	
			
			set @name = (select left(@name,len(@name)-9))
			--print 'AL unit Name2- ' + @name
			
			

			set @SQL = @SQL 
			+'set ' + @name + '_al_value = ' + char(13)
			--print @SQL
	--**********use this section if the user specifies a target unit**************************
			if (select count(@target_unit)) >0 
			begin
				set @SQL = @SQL+'hai.fn_thousands_separator(equis.unit_conversion(cast([' +  @name  + '_al_value] as float)' +  ', [' +  @name +  '_al_unit]' + ' , '  + '''' + @target_unit + '''' + ',default))' + char(13)
				set @SQL = @SQL + 'Where [' +  @name  + '_al_value]' +  ' is not null' + char(13)
				set @SQL = @SQL + char(13) + 'Update ##R set ['+ @name +  '_al_unit] = ' + '''' + @target_unit  + '''' + ' where [' + @name +  '_al_unit] is not null'
			end

	--***********use this section if no target unit and we're using the report_unit instead*************
			if (select count(@target_unit)) =0  
			begin
				set @SQL = @SQL+'hai.fn_thousands_separator(equis.unit_conversion(cast(' +  @name  + '_al_value as float)' +   ', ' +  @name +  '_al_unit' +  ', report_unit ,default))' + char(13)
				set @SQL = @SQL + 'Where ' + '''' + @name  + '_al_value' + '''' + ' is not null' + char(13)
				set @SQL = @SQL + char(13) + 'Update ##R set '+ @name +  '_al_unit = report_unit where [' + @name +  '_al_unit] is not null'

			end

			--begin try
				print  'update units ' + @SQL
				exec  (@SQL)
			--end try
			--begin catch
				--print 'update units failed'
			--end catch


			set @SQL = 'update ##r ' + char(13)
			set @SQL = @sql + ' set  ' + @name  + '_al_value   = ' + @name  + '_al_value + coalesce(' + @name + '_al_subscript,'''')'
			print char(10) + 'update subscripts ' +  @SQL
			exec  (@SQL)

			set @SQL = 'update ##r ' + char(13)
			delete @al_unit where left(col_name,len(@name)) = @name
		end

	/***************************************************/

	

	/*******************************************************/
	/*Add Location Parameters if selected by the user*/
	if (select @include_loc_params) = 'Y'
		begin
			begin try
				exec [rpt].[sp_HAI_location_parameters_xtab] @facility_id, @include_loc_params
				print '##loc_params created'
			end try
			begin catch
				print 'Create ##loc_params failed'
				print error_message()
			end catch
			/*Get the final results with location parameters*/
			select * from ##r r
			left join ##loc_params lp on r. facility_id = lp.facility_id1 and r.sys_loc_code = lp.sys_loc_code1
		end


		--update date range for duplicate samples (PGE)

		update ##r 

		set sample_end_datetime =y.max_end

		from  ##r r 
		inner join (
		select z.sample_name, z.max_end , x.min_end
		from (
		select   distinct sample_name, max(sample_end_datetime) max_end
		from ##r 
		group by sample_name,sample_date_range)z

		left join 
		(select   distinct sample_name, min(sample_end_datetime) min_end
		from ##r 
		group by sample_name,sample_date_range)x
		 on z.sample_name = x.sample_name 

		where max_end > min_end)y
		on r.sample_name = y.sample_name

		update ##r
		set sample_date_range = 
		

		 case when datediff(day,sample_date,sample_end_datetime)  > 0 then

		
				case when datepart(month,sample_date) < 10 then '0' 
					+ cast(datepart(month,sample_date) as varchar) else cast(datepart(month,sample_date) as varchar) end
					+ '/' 
					+ case when datepart(day,sample_date) < 10 then '0' 
					+ cast(datepart(day,sample_date) as varchar) else cast(datepart(day,sample_date) as varchar) end 
				
				+ '-' + 

				case when datepart(month,sample_end_datetime) < 10 then '0' 
					+ cast(datepart(month,sample_end_datetime) as varchar) else cast(datepart(month,sample_end_datetime) as varchar) end
					+ '/' 
					+ case when datepart(day,sample_end_datetime) < 10 then '0' 
					+  cast(datepart(day, sample_end_datetime) as varchar) else cast(datepart(day, sample_end_datetime) as varchar) end
					+ '/' + cast(datepart(year,sample_end_datetime) as varchar) 


				else 
					case when datepart(month,sample_end_datetime) < 10 then '0' 
						+ cast(datepart(month,sample_end_datetime) as varchar) else cast(datepart(month,sample_end_datetime) as varchar) end
						+ '/' 
						+ case when datepart(day,sample_end_datetime) < 10 then '0' 
						+  cast(datepart(day, sample_end_datetime) as varchar) else cast(datepart(day, sample_end_datetime) as varchar) end
						+ '/' + cast(datepart(year,sample_end_datetime) as varchar) 
					
			end

			--case
			-- when datepart(day,sample_end_datetime) - datepart(day,sample_date) >0 then
			--	case when datepart(month,sample_date) < 10 then '0' + cast(datepart(month,sample_date) as varchar) else cast(datepart(month,sample_date) as varchar) end
			--	+ '/' + case when datepart(day,sample_date) < 10 then '0' + cast(datepart(day,sample_date) as varchar) else cast(datepart(day,sample_date) as varchar) end 
			--	+ '-' + 
			--	case when datepart(month,sample_date) < 10 then '0' + cast(datepart(month,sample_date) as varchar) else cast(datepart(month,sample_date) as varchar) end
			--		+ '/' +
			--	case when datepart(day,sample_end_datetime) < 10 then '0' +  cast(datepart(day, sample_end_datetime) as varchar) else cast(datepart(day, sample_end_datetime) as varchar) end
			--		+ '/' + cast(datepart(year,sample_end_datetime) as varchar) 

			-- else 
			--	sample_date
			--end

		from ##r
		

		/*get the final results from ##r without location parameters*/
	if (select @include_loc_params) <> 'Y' or (select count(@include_loc_params)) = 0
		begin
			select * from ##r
		end

		set @elapsed_time = getdate() - @start_time
		set @time_msg =  'total time:' + convert(varchar,@elapsed_time,114) 
		raiserror(@time_msg	,0,1) with nowait


	--just in case... :-)
	IF OBJECT_ID('tempdb..##r') IS NOT NULL drop table ##r
	IF OBJECT_ID('tempdb..##AL') IS NOT NULL drop table ##AL
	IF OBJECT_ID('tempdb..##loc_params') IS NOT NULL drop table ##loc_params
