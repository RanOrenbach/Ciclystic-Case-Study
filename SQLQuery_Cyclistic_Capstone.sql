/** Import Data **/

-- preview of the first table
SELECT TOP (1000) *
 FROM TripData_202104

/** checking data types for all the tables **/

select data_type
from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME = 'TripData_202104'

select data_type
from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME = 'TripData_202105'

select data_type
from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME = 'TripData_202106'

select data_type
from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME = 'TripData_202107'
select data_type
from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME = 'TripData_202108'

select data_type
from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME = 'TripData_202109'
select data_type
from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME = 'TripData_202110'

select data_type
from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME = 'TripData_202111'
select data_type
from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME = 'TripData_202112'

select data_type
from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME = 'TripData_202201'

select data_type
from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME = 'TripData_202202'

select data_type
from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME = 'TripData_202203'

-- changing data type before Union tables --
alter table TripData_202104
alter column end_station_id nvarchar(100);

alter table TripData_202107
alter column end_station_id nvarchar(100);

alter table TripData_202107
alter column start_station_id nvarchar(100);

alter table TripData_202111
alter column start_station_id nvarchar(100);

/** creating temp table dataset that contains yearly data  **/
drop table if exists #year_data
select *
into #year_data
from
(
	select *
	from TripData_202104
	union all
	select * 
	from TripData_202105
	union all
	select *
	from TripData_202106
	union all
	select * 
	from TripData_202107
	union all
	select *
	from TripData_202108
	union all
	select * 
	from TripData_202109
	union all
	select *
	from TripData_202110
	union all
	select * 
	from TripData_202111
	union all
	select *
	from TripData_202112
	union all
	select * 
	from TripData_202201
	union all
	select *
	from TripData_202202
	union all
	select * 
	from TripData_202203
	) as year

-- checking the number of rows in the total data
select count(*) as num_of_rows
from #year_data

-----------------------------------------> Cleaning <--------------------------------------------------

--------- checking every column ----------

---- 1. ride_id ----
select distinct ride_id
from #year_data
order by 1

select ride_id, count(ride_id) as count_duplications
from #year_data
group by ride_id 
having count(ride_id) >1
order by count_duplications

-- remove duplications of ride_id
with CTE_ride_id as
	(
	select ride_id, 
	row_number () over (partition by ride_id order by ride_id) as duplicate_ride_id
	from #year_data
	)
delete from CTE_ride_id
where duplicate_ride_id >1

--remove ride_id if characters number not equal to 16
select count(*) 
from #year_data
where len(ride_id) <> 16

delete from #year_data
where len(ride_id) <> 16

--Trim
update #year_data
set ride_id = trim(ride_id) 

---- 2. rideable_type ----
select distinct rideable_type
from #year_data

select count(rideable_type)
from #year_data
where [month] = 'January'

---- 3. started_at and ended_at ----
select started_at, ended_at, DATEDIFF(minute, started_at, ended_at) as ride_length2
from #year_data
order by started_at 

---separate to different columns of year, month, day---

--first adding columns 
alter table #year_data
	add ride_duration int,
		[year] int,
		[month] nvarchar (10),
		[day] int,
		[hour] int,
		day_of_the_week nvarchar (10),
		time_of_day nvarchar (10)

-- then insert data into the new columns
update #year_data
	set ride_duration = DATEDIFF(minute, started_at, ended_at),
		[year] = DATEPART(year, started_at),
		[month] = DATENAME(month, started_at),
		[day] =  DATEPART(day, started_at),
		[hour] = DATEPART(hour, started_at),
		day_of_the_week = DATENAME(weekday, started_at)

-- define time of day 
update #year_data
	set time_of_day = case 
						when [hour] between 6 and 12 then 'Morning'
						when [hour] between 13 and 17 then 'Afternoon'
						when [hour] between 18 and 22 then 'Evening'
						else 'Night'
						end

-- checking the new columns
	

--checking and removing data when ride_duration is zero or negative
select count(*)
from #year_data
where ride_duration <=0 

delete from #year_data
where ride_duration <=0

--------- 4. start_staion name, end_station_name, start_station_id, end_station_id
---check if we need to adress the nulls at both stations id and stations names 
select count(distinct start_station_name)
from #year_data --861

select count(distinct end_station_name)
from #year_data --859

select count(distinct start_station_id)
from #year_data --849

select count(distinct end_station_id)
from #year_data --849

--remove nulls from stations names only
select start_station_name, end_station_name
from #year_data
where start_station_name is null OR end_station_name is null

delete from #year_data
where start_station_name is null OR end_station_name is null

--remove trim if exists
update #year_data
set start_station_name = trim(start_station_name)

update #year_data
set end_station_name = trim(end_station_name)

update #year_data
set start_station_id = trim(start_station_id)

update #year_data
set end_station_id = trim(end_station_id)


--- 5. start_lat, start_lng, end_lat, end_lng
--checking for nulls
select start_lat, start_lng, end_lat, end_lng
from #year_data
where start_lat is null OR start_lng is null OR end_lat is null OR end_lng is null

------ 6. member_casual
--- check if trim needed 
select distinct member_casual 
from #year_data




----------------------------analysis for differnces between member and casual users

--- ride duration  
select member_casual, count(ride_id) as num_of_rides, max(ride_duration) as max_duration, Avg(ride_duration) as avg_duration, Min (ride_duration) as min_duration
from #year_data
group by member_casual
order by 2

--how many riders took bike for more than 24 hours
select count(*) as count_long_ride
from #year_data
where ride_duration >=1440 --1210

---- rideable_type
select rideable_type, member_casual, count(ride_id) as num_of_rides
from #year_data
group by rideable_type, member_casual
order by 2 desc

--- start_station
select start_station_name, member_casual, count(ride_id) as num_of_rides, avg(ride_duration) as avg_ride_duration
from #year_data
group by member_casual, start_station_name
order by 3 desc

--- end_station
select end_station_name, member_casual, count(ride_id) as num_of_rides, avg(ride_duration) as avg_ride_duration
from #year_data
group by member_casual, end_station_name
order by 3 desc

---check the 10 most common stations 
select top 10 (start_station_name), member_casual, count(ride_id) as num_of_rides, avg(ride_duration) as avg_ride_duration
from #year_data
group by member_casual, start_station_name
order by 3 desc

select top 10 (end_station_name), member_casual, count(ride_id) as num_of_rides, avg(ride_duration) as avg_ride_duration
from #year_data
group by member_casual, end_station_name
order by 3 desc

---- month
select [month], count(ride_id) as num_of_rides, member_casual
from #year_data
group by [month], member_casual
order by 2 desc

--- day of the week
select day_of_the_week, count(ride_id) as num_of_rides, member_casual
from #year_data
group by day_of_the_week, member_casual
order by 2 desc

--time of day
select time_of_day, count(ride_id) as num_of_rides, member_casual
from #year_data
group by time_of_day, member_casual
order by 2 desc

----- check members and casual users differences between month and ride duration
select avg(ride_duration) as avg_duration, count(ride_id) as num_of_rides, member_casual, [month], day_of_the_week, time_of_day
from #year_data
group by member_casual, [month], day_of_the_week, time_of_day
order by num_of_rides desc, avg_duration desc



select top 10 (start_station_name), avg(ride_duration) as avg_duration, count(ride_id) as num_of_rides, member_casual, [month], day_of_the_week, time_of_day
from #year_data
where member_casual ='casual'
group by member_casual, [month], day_of_the_week, time_of_day, start_station_name
order by num_of_rides desc, avg_duration desc

select top 10 (start_station_name),  avg(ride_duration) as avg_duration, count(ride_id) as num_of_rides, member_casual, [month], day_of_the_week, time_of_day
from #year_data
where member_casual ='member'
group by member_casual, [month], day_of_the_week, time_of_day, start_station_name
order by num_of_rides desc, avg_duration desc


select *
from #year_data


---for viz in Tableau
select start_station_name, avg(ride_duration) as avg_duration, count(ride_id) as num_of_rides, member_casual
from #year_data
group by member_casual, start_station_name
having count(ride_id) >=18110
order by num_of_rides desc, avg_duration desc

