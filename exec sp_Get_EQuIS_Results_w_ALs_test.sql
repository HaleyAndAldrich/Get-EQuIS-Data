
use equis
go

set ansi_warnings off
exec  [hai].[sp_Get_EQuIS_Results_w_ALs_test]
	
		 47, --@facility_id int,
		 null, --@location_groups varchar (2000),
		 null , --@locations varchar (2000),
		 'n', --@sample_type varchar(200),
		 'PGE-P39-EB', --'0459007-PAMS|0459007-PAMS-Back',--'ROW_GW_2016_1Q|ROW_GW_2016_2q|ROW_GW_2016_3Q', --@task_codes varchar (1000),
		 null, --@SDG varchar (2000),
		 '1/1/2000', --@start_date datetime, --= 'jan 01 1900 12:00 AM',
		'1/1/2050', --datetime,  -- ='dec 31 2050 11:59 PM',
		 null, --@analyte_groups varchar(2000),
		 null, --@cas_rns varchar (2000),
		 null,-- --@matrix_codes varchar (500),
		 null, --'ug/m3',  --@target_unit varchar(100),
		 'rl', -- @limit_type varchar (10) = 'RL',
		 null, --@action_level_codes varchar (500),
		 null, --'PM10_Max_1h_Avg|PM10_Overall_Avg|TVOC_15_Min_Avg|TVOC_Overall_Avg', -- @loc_param_codes varchar(2000) ,
		 'Elevation Range|Mudline Elevation', --@include_loc_params varchar(10) = 'N',
		 '< # Q', --@user_qual_def varchar (10),
		 'y', --@show_val_yn varchar(10) ,
		 null, --@coord_type varchar (20),
		 'n' -- @detects_only varchar (10) = 'N'  /*returns all samples/chemicals if any one sample had that chemcial detected*/
	

	