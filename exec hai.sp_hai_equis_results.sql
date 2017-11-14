
use equis
go

declare @task_codes varchar(500) = 
'EH_DLW_2015Jan|EH_DLW_2015Sep|EH_SE_2015Dec|EH_SE_2015Jan|EH_SE_2016Mar|EH_SE_2016Oct|EH_SE_Leidos|EH_SEA_SE_PORE_2015'

declare @cas_rns varchar (1000) ='91-20-3' --= (select cas_Rn from rt_analyte where chemical_name like 'anthracene')

exec hai.sp_hai_equis_results

		47, --@facility_id int,
		null,
		 '1/1/1900', --@start_date datetime, --= 'jan 01 1900 12:00 AM',
		'2/1/2050', --datetime,  -- ='dec 31 2050 11:59 PM',
		 'n|fd',  --@sample_type varchar(200),
		 null, --@matrix_codes varchar (500),
		 @task_codes, --@task_codes
		 null, --loc groups
		 null, -- locs
		 null, --'320205661|320217101|320202681', --sdg
		 null, --@analyte_groups varchar(2000),
		 null, --'79-01-6', --@cas_rns varchar (2000),
		 null,  --@analytic_methods
		 null, --'ug/m3',  --@target_unit varchar(100),
		 'rl', -- @limit_type varchar (10) = 'RL',
		 null --@coord_type varchar (20),



		 select * from ##results
		 --where sample_id = 3630874


