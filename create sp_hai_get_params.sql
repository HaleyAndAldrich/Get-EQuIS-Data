USE [equis]
GO
/****** Object:  StoredProcedure [HAI].[sp_HAI_GetParams]    Script Date: 3/14/2017 10:55:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
set ansi_warnings off
go

ALTER procedure [HAI].[sp_HAI_GetParams](
  @facility_id int 
 ,@mth_grp varchar(2000)  
 ,@param varchar(2000) )

as

IF OBJECT_ID('tempdb..##MthGrps')IS NOT NULL 
begin
DROP TABLE ##MthGrps
end

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
	set nocount on
	set ansi_warnings off
	declare @start_time  decimal(10,4)
	declare @elapsed_Time decimal(10,4)
	declare @timemsg varchar (300)

	set @start_Time = datepart(second,getdate())
	set @elapsed_Time = datepart(second,getdate())
	set @timemsg = 'Start ' + cast(@elapsed_time - @start_time as varchar)
	raiserror(@timemsg, 0,1) with nowait

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
	set @timemsg =  '1 ' + cast(@elapsed_time - @start_time as varchar)
	raiserror (@timemsg, 0,1) with nowait
	
	if (select  count(@param)) <> 0
	begin
		set nocount on
		set ansi_warnings off
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
			and r.cas_rn in (select cast(value as varchar(2000)) from fn_split(@param)) 
	end
	set @elapsed_Time = datepart(second,getdate())
	set @timemsg = '2 ' + cast(@elapsed_time - @start_time as varchar)	
	raiserror (@timemsg, 0,1) with nowait


	if (select count(*) from ##MthGrps) = 0 and (select  count(@mth_grp)) = 0 and (select  count(@param)) = 0 
	begin
		set nocount on
		set ansi_warnings off
		insert into ##MthGrps
			select distinct
			t.facility_id
			, 'none selected'
			,ra.chemical_name
			, r.cas_rn
			, analytic_method
			, case when fraction = 'N' then 'T' else fraction end as fraction
			,'99' 
			,'99'
			,null
			from equis.dbo.dt_sample s
			inner join equis.dbo.dt_test t on s.sample_id = t.sample_id and s.facility_id = t.facility_id 
			inner join equis.dbo.dt_result r on t.facility_id = r.facility_id and t.test_id = r.test_id
			inner join rt_analyte ra on r.cas_rn = ra.cas_rn
			where s.facility_id = @facility_id 
			and (result_type_code = 'trg' or result_type_code = 'fld')

	end
	

	set @elapsed_Time = datepart(second,getdate())
	set @timemsg = '3 ' + cast(@elapsed_time - @start_time as varchar)
	raiserror (@timemsg, 0,1) with nowait

	update ##Mthgrps
	set param_report_order =
	case when len(param_report_order) = 1 then '0' + cast(param_report_order as varchar) else param_report_order end

	


