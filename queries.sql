#9
#lets say facility id is 5
/*
Get details of all the employees currently working in a specific facility who have at
least one secondary residence. Details include employee’s first-name, last-name, start
date of work, date of birth, Medicare card number, telephone-number, primary address,
city, province, postal-code, citizenship, email address, and the number of secondary
residences. Results should be displayed sorted in descending order by start date, then
by first name, then by last name.
*/
drop procedure if exists detailOfFacilityMembersWithSecondaryResidences
delimiter $$
create procedure detailOfFacilityMembersWithSecondaryResidences(
	in facility_id int
)
begin
SELECT 
    P.firstName,
    P.lastName,
    E.startDate,
    P.dateOfBirth,
    P.medicare,
    R.telephone,
    R.address,
    R.city,
    R.province,
    R.postalCode,
    P.citizenship,
    P.email,
    COALESCE(SR.numSecondaryResidences, 0) AS numSecondaryResidences
FROM
    Employees AS E
JOIN
	Persons AS P ON E.pid = P.pid
JOIN
    PrimaryLiving AS PR ON E.pid = PR.pid
JOIN
	Residences As R ON PR.rid = R.rid
LEFT JOIN
    (SELECT pid, COUNT(*) AS numSecondaryResidences
     FROM SecondaryLiving
     GROUP BY pid
    ) AS SR ON E.pid = SR.pid
WHERE 
    SR.numSecondaryResidences >= 1
AND
    E.fid = facility_id
ORDER BY
    E.startDate DESC,
    P.firstName DESC,
    P.lastName DESC;

end $$

delimiter ;
call detailOfFacilityMembersWithSecondaryResidences(5);

#10
#Find example for 10
/*
For a given employee, get the details of all the schedules she/he has been scheduled
during a specific period of time. Details include facility name, day of the year, start
time and end time. Results should be displayed sorted in ascending order by facility
name, then by day of the year, the by start time
*/
drop procedure if exists detailPersonScheduleInTimeFrame;

delimiter $$
create procedure detailPersonScheduleInTimeFrame(
    in given_pid int,
    in start_date DATE,
    in end_date DATE
)
begin
SELECT
	F.name,
	S.date,
	S.startTime,
	S.endTime
FROM
	Schedule AS S
JOIN
	Employee AS E ON Schedule.pid = Employee.pid
JOIN
	Facility AS F ON Schedule.fid= Facility.fid
WHERE
E.pid = given_pid
AND S.date> start_Date AND S.date < end_Date
ORDER BY
	F.name ASC,
	S.date ASC,
	S.startTime;

end $$

delimiter ;


# 11 
# lets say person id is 1
/*
 For a given employee, get the details of all the people who live with the employee at 
the primary address and at all the secondary addresses. For every address the employee 
has, you need to provide the residence type for that address, and for every person who 
lives at that address, you need to provide the person’s first name, last name, occupation 
of the person, and the relationship with the employee.
*/

drop procedure if exists detailPeopleWhoLiveWith;

delimiter $$
create procedure detailPeopleWhoLiveWith(
	in given_pid int
)
begin

select distinct per.pid, per.firstName, per.lastName, per.occupation, rela.pid1, rela.pid2, rela.type, r1.rid, r1.type, r1.address, r1.isPrimary
	from Persons per
    left outer join Relationship rela on ((rela.pid1 = per.pid and rela.pid2 = given_pid)  or (rela.pid1 = given_pid and rela.pid2 = per.pid))
    join PrimaryLiving p on per.pid = p.pid
    join SecondaryLiving s on  per.pid = s.pid
    join (# get every rid of 1
			select distinct r.rid, r.type, r.address, r.rid = p.rid as isPrimary
				from PrimaryLiving p, SecondaryLiving s, Residences r
				where 
					p.pid = given_pid
					and p.pid = s.pid
					and (r.rid = p.rid or r.rid = s.rid) 
		) r1
		on r1.rid = p.rid or r1.rid = s.rid
	where
		per.pid != given_pid;

end $$

delimiter ;

call detailPeopleWhoLiveWith(1);


# 12
#Find Example
/*
Get details of all the doctors who have been infected by COVID-19 in the past two
weeks. Details include doctor’s first-name, last-name, date of infection, the name of
the facility that the doctor is currently working for, and the number of secondary
residences the doctor has. Results should be displayed sorted in ascending order by the
facility name, then by the number of secondary residences the doctor has.
*/

drop procedure if exists detailDoctorsInfected;

delimiter $$
create procedure detailDoctorsInfected(
	in specified_date DATE
)
begin

SELECT
	P.firstName,
	P.lastName,
	I.infectionDate //i forgot the label
	F.name,
  	COALESCE(SR.numSecondaryResidences, 0) AS num_secondary_residences
FROM 
 	Employees AS E
JOIN
 	Persons AS P ON E.pid = P.pid
JOIN 
    	Infections AS I ON E.pid = I.pid
JOIN 
    	Facilities AS F ON E.fid = F.fid
LEFT JOIN 
    	(SELECT employee_id, COUNT(*) AS numSecondaryResidences
     	FROM SecondaryLiving
     	GROUP BY employee_id
    	) AS SR ON E.employee_id = SR.employee_id
WHERE 
    	E.role = 'Doctor'
    	AND I.date_of_infection >=DATE_SUB(specified_date, INTERVAL 2 WEEK)
ORDER BY 
    	F.facility_name ASC,
    	COALESCE(SR.numSecondaryResidences, 0) ASC;
end $$

delimiter ;

#13
#Find Example
/*
For a given facility, list the emails generated for the cancellation of assignments during
a specific period of time. The results should be displayed in descending order by the
date of the emails.
*/

drop procedure if exists detailCancelledAppointmentsByFID;

delimiter $$
create procedure detailCancelledAppointmentsByFID(
	in given_fid int
	in specified_date DATE
)
begin
	
SELECT 
   P.first_name,
   P.last_name,
   P.email,
   S.date
FROM 
    Schedule AS S
JOIN 
    Persons AS P ON S.pid = P.pid
JOIN 
    Infections AS I ON P.pid = I.pid
WHERE 
    S.fid = given_pid
    AND S.scheduled_date >= DATE_SUB(specified_date, INTERVAL 2 WEEK)
    AND I.date_of_infection >= DATE_SUB(specified_date, INTERVAL 2 WEEK)
ORDER BY 
    S.scheduled_date DESC;

end $$

delimiter ;

#15
#Find Example
/*
Get details of nurses who are currently working at two or more different facilities and
have been infected by COVID-19 in the last two weeks. Details include first-name,
last-name, first day of work as a nurse, date of birth, email address, total number of
times the nurse got infected by COVID-19, total number of vaccines the nurse had,
total number of hours scheduled, and total number of secondary residences. Results
should be displayed sorted in ascending order by first day of work, then by first name,
then by last name.

*/
    
drop procedure if exists detailInfectedNurseInTwoFacilities;

delimiter $$
create procedure detailInfectedNurseInTwoFacilities(
	in specified_date DATE
)
begin
SELECT
	P.firstName,
	P.lastName, 
	E1.startDate, 
	P.dateOfBirth, 
	P.email,
	COUNT(I.infection_id) AS numInfections,
	COUNT(V.vaccine_id) AS numVaccines,
	SUM(TIMESTAMPDIFF(HOUR, S.startTime, S.endTime)) AS total_hours_scheduled,
    	COALESCE(SR.numSecondaryResidences, 0) AS num_secondary_residences
FROM
 	Employees AS E1
JOIN
	Employees AS E2 ON E1.pid = E2.pid,
JOIN 
	Infections AS I ON E.pid = I.pid,
JOIN
	Persons AS P ON E1.pid = P.pid,
JOIN	
	Vaccines AS V ON E1.pid = V.pid,
JOIN
	Schedule AS S ON E1.pid = S.pid
LEFT JOIN 
    	(SELECT pid, COUNT(*) AS numSecondaryResidences
     	FROM SecondaryResidence
     	GROUP BY pid
    	) AS SR ON P.pid = SR.pid
WHERE 
        	E1.fid != E2.fid
        	AND E1.endDate IS NULL
        	AND E2.endDate  IS NULL
        	AND E1.role = 'nurse'
        	AND I.type = 'COVID-19'
        	AND I.date >= DATE_SUB(specified_date, INTERVAL 2 WEEK)
GROUP BY
	P.pid	
ORDER BY
	E1.startDate ASC,
	P.first_name ASC,
    	P.last_name ASC;
end $$

delimiter ;


#18
#Find Example
/*
For all provinces, give the total number of facilities, the total number of employees
currently working in the facilities, the total number of employees currently working
and infected by COVID-19, the maximum capacity of the facilities, and the total hours
scheduled in all facilities during a specific period. Results should be displayed in
ascending order by province.

*/

drop procedure if exists detailFacilitiesByProvince;

delimiter $$
create procedure detailFacilitiesByProvince(
    in start_date DATE,
    in end_date DATE
)
begin
SELECT 
    	F.province,
    	COUNT(DISTINCT F.fid) AS total_facilities,
SUM(CASE WHEN E.endDate IS NULL THEN 1 ELSE 0 END) AS total_employees_working,
SUM(CASE WHEN I.type = 'COVID-19' THEN 1 ELSE 0 END) AS total_infected_employees,
    	F.capacity 
    	SUM(TIMESTAMPDIFF(HOUR, S.start_time, S.end_time)) AS total_hours_scheduled
FROM 
    	Facilities AS F
LEFT JOIN 
    	Employees AS E ON F.fid = E.fid
LEFT JOIN 
    	Infections AS I ON E.pid = I.pid
LEFT JOIN 
    	Schedules AS S ON F.fid = S.fid
WHERE 
    S.scheduled_date BETWEEN start_date AND end_date
GROUP BY 
    F.province
ORDER BY 
    F.province ASC;

end $$

delimiter ;



# -------------- 15 by adam
        
/*

 Get details of nurses who are currently working at two or more different facilities and 
have been infected by COVID-19 in the last two weeks. Details include first-name, 
last-name, first day of work as a nurse, date of birth, email address, total number of 
times the nurse got infected by COVID-19, total number of vaccines the nurse had, 
total number of hours scheduled, and total number of secondary residences. Results 
should be displayed sorted in ascending order by first day of work, then by first name, 
*/

select per.firstName, per.lastName, cp.startDate, per.dateOfBirth, per.email, cp.icount, count(v.pid), sum(s.endTime - s.startTime), count(sec.rid)
	from Persons per
    join Infections i on per.pid = i.pid
    join Vaccines v on v.pid = per.pid
    join Schedule s on s.pid = per.pid
    join SecondaryLiving sec on sec.pid = per.pid
    join (
    
		# nurses who are currently working at two or more different facilities and have been infected by COVID-19 in the last two weeks.
		select p.pid, e1.startDate, count(i.pid) as icount
			from Employees e1, Employees e2, Infections i, Persons p
			where 
				e1.pid = e2.pid
				and e1.fid < e2.fid
				and e1.endDate = null
				and e2.endDate = null
				and e1.role = 'nurse'
				and e1.pid = i.pid
				and i.type = 'COVID-19'
				and i.date >= DATE_SUB(CURDATE(), INTERVAL 2 WEEK)
				and e1.pid = p.pid
			group by p.pid, e1.startDate
    
    ) cp on cp.pid = per.pid
    group by per.firstName, per.lastName, cp.startDate, per.dateOfBirth, per.email, cp.icount
    order by cp.startDate, per.firstName, per.lastName;

	
    
    # testing
    select p.pid, e1.startDate, count(i.pid) as icount
			from Employees e1, Employees e2, Infections i, Persons p
			where 
				e1.pid = e2.pid
				and e1.fid < e2.fid
				and e1.endDate = null
				and e2.endDate = null
				and e1.role = 'nurse'
				and e1.pid = i.pid
				and i.type = 'COVID-19'
				and i.date >= DATE_SUB(CURDATE(), INTERVAL 100 month )
				and e1.pid = p.pid
			group by p.pid, e1.startDate;

# -------------- 15 by adam

