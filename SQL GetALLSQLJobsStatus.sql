-- list jobs and schedule info with daily and weekly schedules
-- jobs with a daily schedule
SELECT		sysjobs.name job_name
			,sysjobs.enabled job_enabled
			,sysschedules.name schedule_name
			,sysschedules.freq_recurrence_factor
			,CASE WHEN freq_type = 4 THEN 'Daily' END frequency
			,'every ' + cast (freq_interval as varchar(3)) + ' day(s)'  Days
			,CASE WHEN freq_subday_type = 2 THEN ' every ' + cast(freq_subday_interval as varchar(7)) 
					+ ' seconds' + ' starting at '
					+ stuff(stuff(RIGHT(replicate('0', 6) +  cast(active_start_time as varchar(6)), 6), 3, 0, ':'), 6, 0, ':')
				  WHEN freq_subday_type = 4 THEN ' every ' + cast(freq_subday_interval as varchar(7)) 
					+ ' minutes' + ' starting at '
					+ stuff(stuff(RIGHT(replicate('0', 6) +  cast(active_start_time as varchar(6)), 6), 3, 0, ':'), 6, 0, ':')
				  WHEN freq_subday_type = 8 THEN ' every ' + cast(freq_subday_interval as varchar(7)) 
					+ ' hours'   + ' starting at '
					+ stuff(stuff(RIGHT(replicate('0', 6) +  cast(active_start_time as varchar(6)), 6), 3, 0, ':'), 6, 0, ':')
				  ELSE ' starting at ' +stuff(stuff(RIGHT(replicate('0', 6) +  cast(active_start_time as varchar(6)), 6), 3, 0, ':'), 6, 0, ':')
			 END time,
			run_status
FROM		msdb.dbo.sysjobs
inner join	msdb.dbo.sysjobschedules on sysjobs.job_id = sysjobschedules.job_id
inner join	msdb.dbo.sysschedules on sysjobschedules.schedule_id = sysschedules.schedule_id
inner join	(
				Select	*
				FROM	(
							Select	* 
									,ROW_NUMBER()OVER(PARTITION BY Job_ID Order by CONVERT(DATE, CAST(run_date as varchar(50)), 112) desc) RN
							From	msdb.dbo.sysjobhistory
						) X
				WHERE	X.RN = 1
			) X on sysjobs.job_id = X.job_id
WHERE		freq_type = 4
UNION
-- jobs with a weekly schedule
SELECT		sysjobs.name job_name
			,sysjobs.enabled job_enabled
			,sysschedules.name schedule_name
			,sysschedules.freq_recurrence_factor
			,CASE WHEN freq_type = 8 then 'Weekly' END frequency
			,replace(
						CASE WHEN freq_interval&1 = 1 THEN 'Sunday, ' ELSE '' END
						+CASE WHEN freq_interval&2 = 2 THEN 'Monday, ' ELSE '' END
						+CASE WHEN freq_interval&4 = 4 THEN 'Tuesday, ' ELSE '' END
						+CASE WHEN freq_interval&8 = 8 THEN 'Wednesday, ' ELSE '' END
						+CASE WHEN freq_interval&16 = 16 THEN 'Thursday, ' ELSE '' END
						+CASE WHEN freq_interval&32 = 32 THEN 'Friday, ' ELSE '' END
						+CASE WHEN freq_interval&64 = 64 THEN 'Saturday, ' ELSE '' END
						,', '
						,''
					) Days
			,CASE WHEN freq_subday_type = 2 THEN ' every ' + cast(freq_subday_interval as varchar(7)) 
						+ ' seconds' + ' starting at '
						+ stuff(stuff(RIGHT(replicate('0', 6) +  cast(active_start_time as varchar(6)), 6), 3, 0, ':'), 6, 0, ':') 
				   WHEN freq_subday_type = 4 THEN ' every ' + cast(freq_subday_interval as varchar(7)) 
						+ ' minutes' + ' starting at '
						+ stuff(stuff(RIGHT(replicate('0', 6) +  cast(active_start_time as varchar(6)), 6), 3, 0, ':'), 6, 0, ':')
				   WHEN freq_subday_type = 8 THEN ' every ' + cast(freq_subday_interval as varchar(7)) 
						+ ' hours'   + ' starting at '
						+ stuff(stuff(RIGHT(replicate('0', 6) +  cast(active_start_time as varchar(6)), 6), 3, 0, ':'), 6, 0, ':')
				   ELSE ' starting at ' + stuff(stuff(RIGHT(replicate('0', 6) +  cast(active_start_time as varchar(6)), 6), 3, 0, ':'), 6, 0, ':')
			 END time,
			run_status
FROM		msdb.dbo.sysjobs
inner join msdb.dbo.sysjobschedules on sysjobs.job_id = sysjobschedules.job_id
inner join msdb.dbo.sysschedules on sysjobschedules.schedule_id = sysschedules.schedule_id
inner join (
				Select	*
				FROM	(
							Select	* 
									,ROW_NUMBER()OVER(PARTITION BY Job_ID Order by CONVERT(DATE, CAST(run_date as varchar(50)), 112) desc) RN
							From	msdb.dbo.sysjobhistory
						) X
				WHERE	X.RN = 1
			) X on sysjobs.job_id = X.job_id
WHERE		freq_type = 8
ORDER BY job_enabled desc
