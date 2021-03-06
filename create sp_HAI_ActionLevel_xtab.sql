USE [EQuIS]
GO
/****** Object:  StoredProcedure [rpt].[sp_HAI_ActionLevel_xtab]    Script Date: 7/17/2017 9:29:47 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--Creates a crosstab of action levels to append to an EQuIS Results set
--created by Dan Higgins  8/20/2015

/*test to remove equals signs from action level codes*/
ALTER procedure  [rpt].[sp_HAI_ActionLevel_xtab] 
(
 @facility_id int ,
 @action_level_code varchar (2000) 
)
as 
begin


begin try
	--Get a list of action level codes
	declare @al_table table (action_level_code varchar (200))
	insert into @al_table 
	select distinct al_code from
	 [rpt].[fn_HAI_Get_ActionLevels]  (@facility_id,@action_level_code)
end try
begin catch
	select error_message()
end catch



--*************************************************************************
/*Create a dynamic crosstab*/
if (select count(*) from @al_table) > 0  --IF the users selects some ALs them make ##AL
begin
	 declare @al_code varchar (200)
	 declare @SQL1 varchar(max)
	 declare @SQL2 varchar (max) 
	 declare @SQL_Results_Set varchar(max)
	 declare @sql3 varchar (max) = 'IF OBJECT_ID(''tempdb..##al'') IS NOT NULL' + char(13)
		+'BEGIN ' + char(13)
		+'DROP TABLE ##al ' + char(13)
		+'END' + char(13)
		+'Create table ##al(' + char(13)
		+'al_param_code varchar(200), ' + char(13)
	 /*the beginning of the SQL string*/
	 set @SQL1 = 'Select al_param_code, ' + char(13)


	 /*Loop through each action levels and build the output columns*/
	 while (select count(*) from @al_table) >0  --keep going as long as there are action level codes in @al_table
		begin
			set @al_code = (select top 1 action_level_code from @al_table)  --get the next code
			/*build out the body of the Crosstab sql string*/
			set @SQL1 = @SQL1 + 'Max (case when al_code = ' + '''' + @AL_code + '''' +  ' then cast(al_value as varchar)  end) as [' + @al_code + '_AL_value]' + ',' + char(13) 
			set @SQL1 = @SQL1 + 'Max (case when al_code = ' + '''' + @AL_code + '''' +  ' then al_unit end) as [' + @al_code + '_AL_unit]' + ',' + char(13) 
			set @SQL1 = @SQL1 + 'Max (case when al_code = ' + '''' + @AL_code + '''' +  ' then al_fraction end) as [' + @al_code + '_AL_fraction]' + ',' + char(13) 
			set @SQL1 = @SQL1 + 'Max (case when al_code = ' + '''' + @AL_code + '''' +  ' then al_matrix end) as [' + @al_code + '_AL_matrix]' + ',' + char(13) 

			/*not including subscript note reference unless its in parens consistent with PGE reporting*/
			set @SQL1 = @SQL1 + 'Max (case when al_code = ' + '''' + @AL_code + '''' +  ' then case when left(al_subscript ,1) not like ' + '''' + '(' + '''' + ' then ' + '''' +  '[' + '''' + '+ al_subscript +' + '''' +  ']' + '''' + ' else al_subscript   end end ) as [' + @al_code + '_AL_subscript]' + ',' + char(13) 
			
			set @SQL3 = @sql3 
					 + '[' + replace(replace(@al_code,'=','_'),'.','_') + '_AL_value] varchar(50)' + ',' + char(13)
					 + '[' + replace(replace(@al_code,'=','_'),'.','_') + '_AL_unit] varchar (20)' + ',' + char(13)
					 + '[' + replace(replace(@al_code,'=','_'),'.','_') + '_AL_fraction] varchar(10)'+ ',' + char(13)
					 + '[' + replace(replace(@al_code,'=','_'),'.','_') + '_AL_matrix] varchar (30)' + ',' + char(13)
					 + '[' + replace(replace(@al_code,'=','_'),'.','_') + '_AL_subscript] varchar (30)' + ',' + char(13)



			delete @al_table where action_level_code = @al_code --remove the current action level code



		end --finish the loop

	--trim spaces
	set @SQL1 =  rtrim(ltrim(@SQL1))
	--remove the trailing comma from the last statement in the body 
	set @SQL1 = left(@SQL1,len(@SQL1)-2)
	--create the 'FROM' statement
	
	set @SQL2 = char(13) + 'from [rpt].[fn_HAI_Get_ActionLevels]  (' +  cast(@facility_id as varchar) +  ',' +'''' + @action_level_code + '''' + ')'
	set @SQL2 = @SQL2 + char(13)
	+ 'Group by al_param_code' + char(13)

	
	
	--run the SQL strings
	set @SQL_results_set = left(@SQL_results_set,len(@SQL_results_set) -2) + ')'
	print @SQL_results_set

	--Create  ##al TEMP TABLE based on dynamic query columns
	set @SQL3 = left(@SQL3,len(@SQL3) -2)
	set @SQL3 = @SQL3 + ')' + char(13) 
	begin try
	
	print @SQL3
	exec (@sql3 )
	end try
	begin catch
		print char(13) +'Error making ##AL: ' + error_message() + char(13)
		print @sql3 

	end catch


	IF  OBJECT_ID('tempdb..##al') IS NOT NULL
	begin
	print char(13) +'##AL created' + char(13)
	end

	if (select count(@action_level_code)) >0
	begin try
		exec  ('insert into ##AL '+ @SQL1 + @SQL2 )
		print 'Insert to ##AL Completed'
		--select * from ##AL
		end try
	begin catch
		print 'Insert to ##AL failed' + char(13)
		+ error_message() + char(13)
		+ coalesce(@SQL1,'') + coalesce(@SQL2,'')

	end catch
end



if OBJECT_ID('tempdb..##al') IS NULL  --If the user selects no ALs then make a fake table for ##R to link to
	begin
		Create table ##al (al_param_code varchar(200))
		print 'No ALs: Empty ##AL created'
	end

end