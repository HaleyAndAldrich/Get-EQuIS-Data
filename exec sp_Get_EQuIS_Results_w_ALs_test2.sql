
use equis
go

set ansi_warnings off
exec  [hai].[sp_Get_EQuIS_Results_w_ALs_test2]
	
		 7322427, --@facility_id int,
		 null,
		 null, --@location_groups varchar (2000),
		 null, --@locations varchar (2000),
		 null, --@sample_type varchar(200),
		 'parcel b-wg', --@task_codes varchar (1000),
		 null, --@SDG varchar (2000),
		 '1/1/1900', --@start_date datetime, --= 'jan 01 1900 12:00 AM',
		'1/1/2050', --datetime,  -- ='dec 31 2050 11:59 PM',
		 'utc-nc-wg-voc', --@analyte_groups varchar(2000),
		 null, --@cas_rns varchar (2000),
		 null,  --@analytic_methods
		 null,-- --@matrix_codes varchar (500),
		 'ug/l', --'ug/m3',  --@target_unit varchar(100),
		 null, -- @limit_type varchar (10) = 'RL',
		 'FED_RSL-2017-06_MCL-WG|STATE-CA-ESL-WG-IND-FC-GW3-201602|STATE-CA-ESL-WG-IND-S-GW3-201602|STATE-CA-ESL-WG-RES-FC-GW3-201602|STATE-CA-ESL-WG-RES-SAND-GW3-201602', --@action_level_codes varchar (500),
		 null, --'PM10_Max_1h_Avg|PM10_Overall_Avg|TVOC_15_Min_Avg|TVOC_Overall_Avg', -- @loc_param_codes varchar(2000) ,
		 null, --'Elevation Range|Mudline Elevation', --@sample parameters,
		 '< # Q', --@user_qual_def varchar (10),
		 'n', --@show_val_yn varchar(10) ,
		 null, --@coord_type varchar (20),
		 'n', -- @detects_only varchar (10) = 'N'  /*returns all samples/chemicals if any one sample had that chemcial detected*/
		 null
	

