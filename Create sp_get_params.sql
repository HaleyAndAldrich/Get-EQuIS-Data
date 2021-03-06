USE [EQuIS]
GO
/****** Object:  StoredProcedure [rpt].[sp_HAI_GetParams]    Script Date: 12/22/2016 3:04:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER procedure [rpt].[sp_HAI_GetParams](
  @facility_id int 
 ,@mth_grp varchar(2000)  
 ,@param varchar(2000) )

as

IF OBJECT_ID('tempdb..##MthGrps')IS NOT NULL DROP TABLE ##MthGrps
create table ##MthGrps 
( facility_id int
,Grp_Name varchar(100)
,parameter varchar(4000)
,cas_rn varchar (30)
,analytic_method varchar (30)
,fraction varchar (10)
,param_report_order varchar(10)
,mag_report_order varchar(10)
,default_units varchar (10)
,PRIMARY KEY CLUSTERED (facility_id, grp_name, cas_Rn, analytic_method, fraction)
)
	set nocount on

	declare @start_time  decimal(10,4)
	declare @elapsed_Time decimal(10,4)

	set @start_Time = datepart(second,getdate())
	set @elapsed_Time = datepart(second,getdate())
	--print 'Start ' + cast(@elapsed_time - @start_time as varchar)

	insert into ##MthGrps 
	select  facility_id, method_analyte_group_code, chemical_name, cas_rn
	, analytic_method, total_or_dissolved , min(report_order) ,mag_report_order, default_units
	from (
	select  @facility_id as facility_Id,magm.method_analyte_group_code, chemical_name,magm.cas_rn
	, analytic_method, case when total_or_dissolved = 'D' then 'D' else 'T'end as total_or_dissolved , report_order ,mag_report_order, default_units
		from equis.dbo.rt_mth_anl_group_member magm
		inner join equis.dbo.rt_mth_anl_group mag on magm.method_analyte_group_code = mag.method_analyte_group_code 
		where magm.method_analyte_group_code in (select cast(value as varchar(2000)) from fn_split(@mth_grp)) )z

		group by facility_id, method_analyte_group_code, chemical_name, cas_rn, analytic_method,  mag_report_order, default_units, total_or_dissolved

set @elapsed_Time = datepart(second,getdate())
	--print '1 ' + cast(@elapsed_time - @start_time as varchar)
	
	if (select  count(@param)) <> 0
		insert into ##mthgrps
			select distinct
			 @facility_id
			, 'none selected'
			,ra.chemical_name
			, r.cas_rn
			, t.analytic_method
			, case when fraction = 'D' then 'D' else 'T' end as fraction
			, '00'
			, '999'
			,null
			from equis.dbo.dt_Test t 
				inner join equis.dbo.dt_result r on t.facility_id = r.facility_id and t.test_id = r.test_id
				inner join equis.dbo.rt_analyte ra on r.cas_rn = ra.cas_rn
			where r.cas_rn not in (select cas_rn from ##mthgrps)
			and t.facility_id in (select facility_id from equis.facility_group_members(@facility_id)) 
			and ra.chemical_name in (select cast(value as varchar(2000)) from fn_split(@param)) 
		
	--set @elapsed_Time = datepart(second,getdate())
	--print '2 ' + cast(@elapsed_time - @start_time as varchar)	

	if (select count(*) from ##MthGrps) = 0 and (select  count(@mth_grp)) = 0 and (select  count(@param)) = 0 
		insert into ##MthGrps
			select distinct
			s.facility_id
			, 'none selected'
			, c.chemical_name
			, r.cas_rn
			, analytic_method
			, case when fraction = 'N' then 'T' else fraction end as fraction
			,'99' 
			,'99'
			,null
			from equis.dbo.dt_test t 
			inner join equis.dbo.dt_result r on t.test_id = r.test_id and t.facility_id = r.facility_id
			inner join (select distinct facility_id, r.cas_rn ,ra.chemical_name
				from equis.dbo.dt_result r
				inner join equis.dbo.rt_analyte ra on r.cas_rn = ra.cas_Rn			
				where facility_id = @facility_id and result_type_code = 'trg')c
			on r.facility_id = c.facility_id and r.cas_rn = c.cas_rn
			inner join equis.dbo.dt_sample s on t.sample_id = s.sample_id and t.facility_id = s.facility_id 

			where s.facility_id =@facility_id

	
	--set @elapsed_Time = datepart(second,getdate())
	--print '3 ' + cast(@elapsed_time - @start_time as varchar)

	update ##Mthgrps
	set param_report_order =
	case when len(param_report_order) = 1 then '0' + cast(param_report_order as varchar) else param_report_order end

	


