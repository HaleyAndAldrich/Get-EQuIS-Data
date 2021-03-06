USE [EQuIS]
GO
/****** Object:  StoredProcedure [HAI].[sp_HAI_EQuIS_Results]    Script Date: 11/14/2017 9:12:11 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*added compound groups 6/22/2016'*/

ALTER procedure [HAI].[sp_HAI_EQuIS_Results](
	 @facility_id int
	,@subfacility_codes varchar (500)
	,@start_date datetime
	,@end_date datetime
	,@sample_type varchar (100)
	,@matrix_codes varchar (100)
	,@task_codes varchar (1000)
	,@location_groups varchar (1000)
	,@locations varchar (1000)
	,@sdg varchar (1000)
	,@analyte_groups varchar(2000)
	,@cas_rns varchar (2000)
	,@analytic_methods varchar (2000)
	,@target_unit varchar(15)
	,@limit_type varchar (10)
	,@coord_type varchar(20)
	)

as 
begin

	

	exec [hai].[sp_HAI_Get_Locs_temp] @facility_id, @location_groups, @locations  --creates ##locs
	--raiserror ('locs',0,1) with nowait	

/*update ##locs with subfacility codes*/
	if (select @subfacility_codes) is not null
	begin
		delete ##locs where subfacility_code not in (select cast(value as varchar(20)) from fn_split(@subfacility_codes))
		insert into ##locs (facility_id, sys_loc_code, subfacility_code, loc_name, loc_group, loc_report_order, loc_type)
		select facility_id, sys_loc_code, subfacility_code, loc_name, null, null, loc_type
		 from equis.dbo.dt_location 
		 where subfacility_code in (select cast(value as varchar (20)) from fn_split(@subfacility_codes))
		 and sys_loc_code not in (select sys_loc_code from ##locs)
	end


	exec [hai].[sp_HAI_Get_Samples] @facility_id, @start_date, @end_date, @task_codes, @sample_type,@matrix_codes  --creates ##samples
	--raiserror ('samples',0,1) with nowait	

/**Get parameter/method selections*/
	if (select count(@analytic_methods)) = 0
	begin
		exec [hai].[sp_HAI_GetParams] @facility_id,@analyte_groups, @cas_rns --creates ##mthgrps
	end
	if (select count(@analytic_methods)) > 0
	begin
		IF OBJECT_ID('tempdb..##MthGrps')IS NOT NULL DROP TABLE ##MthGrps
		begin
			create table ##MthGrps 
			(rec_id int identity (1,1)  /*rec_id allows ##tests to be unique*/
			,facility_id int
			,Grp_Name varchar(100)
			,parameter varchar(4000)
			,cas_rn varchar (30)
			,analytic_method varchar (30)
			,fraction varchar (10)
			,param_report_order varchar(10)
			,mag_report_order varchar(10)
			,default_units varchar (10)
			,PRIMARY KEY CLUSTERED (rec_id,facility_id, grp_name, cas_Rn, analytic_method, fraction)
)
		end
		insert into ##mthgrps (facility_id ,Grp_Name ,parameter ,cas_rn ,analytic_method ,fraction ,param_report_order ,mag_report_order ,default_units)
		select distinct
			t.facility_id
			,'none'
			,chemical_name
			,r.cas_rn
			,t.analytic_method
			,t.fraction
			,dense_rank() over (partition by analytic_method  order by chemical_name)
			,dense_rank() over (order by analytic_method)
			,null
		from dt_test t
		inner join dt_result r on t.facility_id = r.facility_id and t.test_id = r.test_id
		inner join rt_analyte ra on r.cas_rn = ra.cas_rn
		where t.facility_id = @facility_id
		and t.analytic_method in (select cast(value as varchar (40)) from fn_split(@analytic_methods))
		and r.reportable_result like 'y%'
		and r.result_type_code = 'trg'
		and r.reportable_result = 'yes'

		update ##Mthgrps
		set param_report_order =
		case when len(param_report_order) = 1 then '0' + cast(param_report_order as varchar) else param_report_order end,
		mag_report_order =
		case when len(mag_report_order) = 1 then '0' + cast(mag_report_order as varchar) else mag_report_order end
	end


	exec [hai].[sp_HAI_Get_Tests] @facility_id, @sdg  --creates ##tests  --depends on sp_hai_get_samples and sp_hai_getparams
	--raiserror ('sdgs',0,1) with nowait


	IF OBJECT_ID('tempdb..##results')IS NOT NULL DROP TABLE ##results
	--raiserror ('drop ##results',0,1) with nowait

	Select
		s.facility_id,
		s.sample_id,
		t.test_id,
		ts.mthgrp_rec_id,
		s.sys_sample_code,
		s.sample_name,
		t.lab_sample_id,
		fs.field_sdg,
		l.subfacility_code,
		sf.subfacility_name,
		coalesce(s.sys_loc_code,'none') as sys_loc_code,
		coalesce(l.loc_name,'none') as loc_name,
		l.loc_type,
		coalesce(locs.loc_report_order,'99') as loc_report_order,
		locs.loc_group,
		s.sample_date,
		s.duration,
		s.duration_unit,
		s.matrix_code,
		s.sample_type_code,
		s.sample_source,
		coalesce(s.task_code,'none') as task_code,
		s.start_depth,
		s.end_depth,
		s.depth_unit,
		g.compound_group,
		ts.grp_name as parameter_group_name,
		ts.parameter as mth_grp_parameter,
		ts.param_report_order,
		ts.mag_report_order,
		ts.default_units,
		t.analytic_method,
		t.leachate_method,
		t.dilution_factor,
		t.fraction ,
		t.test_type,
		coalesce(t.lab_sdg,'No_SDG')as lab_sdg,
		t.lab_name_code,
		t.analysis_date,
		ra.chemical_name,
		r.cas_rn,
		r.result_text,
		r.result_numeric,
		r.reporting_detection_limit,
		r.method_detection_limit,
		r.result_error_delta,
		case when r.detect_flag = 'N' then r.reporting_detection_limit else r.result_text end as result,
		r.result_unit as reported_result_unit,
		r.detect_flag,
		r.reportable_result,
		r.result_type_code,
		r.lab_qualifiers,
		r.validator_qualifiers,
		r.interpreted_qualifiers,
		r.validated_yn,
		approval_code,
		approval_a,
		case 
			when validated_yn = 'Y' then r.interpreted_qualifiers
			when r.interpreted_qualifiers is not null then r.interpreted_qualifiers
			when charindex('j',r.lab_qualifiers)> 0 and r.interpreted_qualifiers is null then 'J'
			when charindex('j',r.lab_qualifiers)= 0 and r.interpreted_qualifiers is null and r.detect_flag = 'N' then 'U' 
		end as qualifier,


		case 
			when r.detect_flag = 'N' and coalesce(@limit_type,'RL') = 'RL' then  --default to RL
				equis.significant_figures(equis.unit_conversion_result(coalesce(reporting_detection_limit,result_text), r.result_unit,coalesce(@target_unit, r.result_unit),default,null, null,  null,  r.cas_rn,null),equis.significant_figures_get(coalesce(reporting_detection_limit,result_text) ),default)
			when r.detect_flag = 'N' and @limit_type = 'MDL' then 
				equis.significant_figures(equis.unit_conversion_result(coalesce(method_detection_limit,result_text), r.result_unit,coalesce(@target_unit, r.result_unit),default,null, null,  null,  r.cas_rn,null),equis.significant_figures_get(coalesce(method_Detection_limit,result_text) ),default)
			when r.detect_flag = 'N' and @limit_type = 'PQL' then 
				equis.significant_figures(equis.unit_conversion_result(quantitation_limit, r.result_unit,coalesce(@target_unit, r.result_unit),default,null, null,  null,  r.cas_rn,null),equis.significant_figures_get(quantitation_limit ),default)
			when r.detect_flag = 'Y' then
				equis.significant_figures(equis.unit_conversion_result(r.result_numeric,r.result_unit,coalesce(@target_unit,r.result_unit), default,null, null,  null,  r.cas_rn,null),equis.significant_figures_get(coalesce(r.result_text,rpt.trim_zeros(cast(r.result_numeric as varchar)))),default) 
			end 
			as converted_result, 
	  
			coalesce(case when r.interpreted_qualifiers is not null and charindex(',',r.interpreted_qualifiers) >0 then  left(r.interpreted_qualifiers, charindex(',',r.interpreted_qualifiers)-1)
			when r.interpreted_qualifiers is not null then r.interpreted_qualifiers
			when r.validator_qualifiers is not null then r.validator_qualifiers
			when detect_flag = 'N' and interpreted_qualifiers is null then 'U' 
			when validated_yn = 'N' and charindex('J',lab_qualifiers) >0 then 'J'
			else ''
		end, '') as reporting_qualifier,

		coalesce(@target_unit, result_unit) as converted_result_unit,
		@limit_type as detection_limit_type,
		coord_type_code,
		x_coord,
		y_coord,
		eb.edd_date, 
		eb.edd_user,
		eb.edd_file 

	into ##results
	From dbo.dt_sample s
		inner join dt_test t on s.facility_id = t.facility_id and  s.sample_id = t.sample_id
		inner join dt_result r on t.facility_id = r.facility_id and t.test_id = r.test_id
		inner join rt_analyte ra on r.cas_rn = ra.cas_rn
		inner join dt_location l on s.facility_id = l.facility_id and s.sys_loc_code = l.sys_loc_code

	inner join ##samples ss on s.facility_id = s.facility_id and s.sample_id = ss.sample_id
	inner join ##locs locs on s.facility_id = locs.facility_id and s.sys_loc_code = locs.sys_loc_code
	inner join ##tests ts on t.facility_id = ts.facility_id and ts.sample_id = t.sample_id and t.test_id = ts.test_id and r.cas_rn = ts.cas_rn

		left join dt_subfacility sf on l.facility_Id = sf.facility_id and l.subfacility_code = sf.subfacility_code
		left join dt_field_sample fs on s.facility_id = fs.facility_id and s.sample_id = fs.sample_id
		left join st_edd_batch eb on r.ebatch = eb.ebatch
		left join (select facility_id, sys_loc_code, coord_type_code,x_coord, y_coord 
					from dt_coordinate 
					where facility_id in (select facility_id from equis.facility_group_members(@facility_id)) and coord_type_code = @coord_type)c 
				on s.facility_id = c.facility_id and s.sys_loc_code = c.sys_loc_code


		left join (select member_code ,rgm.group_code as compound_group from rt_group_member rgm
				inner join rt_group rg on rgm.group_code = rg.group_code
				 where rg.group_type = 'compound_group')g
		on t.analytic_method = g.member_code

	Where
	(r.result_type_code = 'trg' or r.result_Type_code = 'fld')
	and (r.reportable_result ='yes' or r.reportable_result = 'y')
	and s.sample_source ='field'
	and 
	(case  --filter out non-numeric values
		when result_text is not null then isnumeric(result_text) 
		when reporting_detection_limit is not null then isnumeric(reporting_detection_limit)
		else -1
		 end) <> 0

	ALTER TABLE ##results   
	ADD CONSTRAINT PK_results PRIMARY KEY CLUSTERED (facility_Id, sample_id, test_id, mthgrp_rec_id, cas_rn);  
	
	raiserror ('End make ##results',0,1) with nowait
end
