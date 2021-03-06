USE [equis]
GO
/****** Object:  StoredProcedure [HAI].[sp_HAI_Get_Tests]    Script Date: 1/6/2017 9:08:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*Creates an indexed global temporary analytical tests table*/

/*Test results returns are filtered by the following....
    -Needs sp_hai_get_samples to populate ##samples
	-Needs sp_getparams to populate ##mthgrps */

ALTER procedure [HAI].[sp_HAI_Get_Tests] (
	@facility_id int, 
	@SDGs varchar(1000)
	)

 as
  begin
	IF OBJECT_ID('tempdb..##tests')IS NOT NULL DROP TABLE ##tests

	create table ##tests
	(facility_id int
	,sample_id int
	,test_id int
	,mthgrp_rec_id int
	,lab_sdg varchar (200)
	,cas_rn varchar (100)
	,parameter varchar (100)
	,grp_name varchar (100)
	,param_report_order varchar (10)
	,mag_report_order varchar (10)
	,default_units varchar (10)
	,PRIMARY KEY CLUSTERED (facility_id, test_id, mthgrp_rec_id, cas_rn)
	)


  if (select count(@SDGs)) >0  --if SDGs are a selection criteria...
	begin
		insert into ##tests
		select t.facility_id, t.sample_id, t.test_id ,mg.rec_id,t.lab_sdg, mg.cas_rn, parameter, grp_name, param_report_order, mag_report_order, default_units 
		from dbo.dt_test t
		inner join ##samples s on t.facility_id = s.facility_id and t.sample_id = s.sample_id  --limit test records to selected samples
		inner join (select rec_id, analytic_method, fraction, cas_rn ,parameter,grp_name, param_report_order, mag_report_order, default_units  from ##mthgrps) mg --limit test records to selected analytical parameters
			on t.analytic_method = mg.analytic_method 
			and (case when t.fraction = 'D' then 'D' else 'T'end) = mg.fraction  --return only D or T (for T or N)
		where lab_sdg in (select cast(value as varchar(200))from equis.split(@SDGs))  --uses dt_test.lab SDG
	end

	if (select count(*) from ##tests) = 0  --if SDGs are NOT a selection criteria
	begin
		insert into ##tests
		select distinct
			t.facility_Id, t.sample_id, t.test_id, mg.rec_id, coalesce(t.lab_sdg, 'No_SDG'), r.cas_Rn , parameter, grp_name, param_report_order, mag_report_order, default_units 
			from dt_test t
			inner join dt_Result r on t.facility_id = r.facility_id and t.test_id = r.test_id
		inner join ##samples s on t.facility_id = s.facility_id and t.sample_id = s.sample_id --limit test records to selected samples
		inner join (select distinct rec_id, analytic_method, fraction, cas_rn, parameter, grp_name, param_report_order, mag_report_order, default_units from ##mthgrps) mg --limit test records to selected analytical parameters
			on t.analytic_method = mg.analytic_method 
			and (case when t.fraction = 'D' then 'D' else 'T'end) = mg.fraction  --return only D or T (for T or N)
			and mg.cas_rn = r.cas_Rn

	end
return
end