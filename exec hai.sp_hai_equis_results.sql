use equis

go


declare @facility_id int = (select facility_id from dt_facility where facility_name like 'north')
declare @cas_rns varchar (1000) ='91-20-3' --= (select cas_Rn from rt_analyte where chemical_name like 'anthracene')

exec hai.sp_hai_equis_results

		47, --@facility_id int,
		 '1/1/2016', --@start_date datetime, --= 'jan 01 1900 12:00 AM',
		'2/1/2017', --datetime,  -- ='dec 31 2050 11:59 PM',
		 'n', --'n|fd', --@sample_type varchar(200),
		 null, --@matrix_codes varchar (500),
		 '0459007-pams', --@task_codes
		 null, --loc groups
		 null, -- locs
		 null, --'320205661|320217101|320202681', --sdg
		 'pge air btex + napth|pge air pahs', --@analyte_groups varchar(2000),
		 @cas_rns, --'79-01-6', --@cas_rns varchar (2000),
		 null, --'ug/m3',  --@target_unit varchar(100),
		 'rll', -- @limit_type varchar (10) = 'RL',
		 null --@coord_type varchar (20),



		 select * from ##results
		 where sample_id = 3630874


