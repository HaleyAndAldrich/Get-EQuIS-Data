

exec hai.sp_hai_equis_results

47, --@facility_id int,
		 '1/1/2000', --@start_date datetime, --= 'jan 01 1900 12:00 AM',
		'1/1/2017', --datetime,  -- ='dec 31 2050 11:59 PM',
		 null, --'n|fd', --@sample_type varchar(200),
		 null, --@matrix_codes varchar (500),
		 '0459007-PAMS', --@task_codes
		 null, --loc groups
		 null, -- locs
		 null, --'320205661|320217101|320202681', --sdg
		 'pge air pahs', --@analyte_groups varchar(2000),
		 null, --'79-01-6', --@cas_rns varchar (2000),
		 null, --'ug/m3',  --@target_unit varchar(100),
		 'rl', -- @limit_type varchar (10) = 'RL',
		 null --@coord_type varchar (20),


		 select * from ##results

