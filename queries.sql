#8
/*
Get details of all the facilities recorded in the system. Details include facility name,
address, city, province, postal-code, phone number, web address, type, capacity, name
of the general manager, number of employees currently working at the facility, number
of doctors currently working in the facility, and number of nurses currently working in
the facility. Results should be displayed sorted in ascending order by province, then by
city, then by type, then by number of doctors currently working for the facility.	
*/	
drop procedure if exists detailOfFacilitiesByRoles
delimiter $$
create procedure detailOfFacilitiesByRoles()	
SELECT 
    E.fid,
    F.address,
    F.city,
    F.province,
    F.postalCode,
    F.telephone,
    F.webAddress,
    F.type,
    F.capacity,
    COUNT(*) AS numEmployees,
    SUM(CASE WHEN E.role = 'doctor' THEN 1 ELSE 0 END) AS numDoctors,
    SUM(CASE WHEN E.role = 'nurse' THEN 1 ELSE 0 END) AS numNurses,
    P_manager.firstName AS managerFirstName,
    P_manager.lastName AS managerLastName
FROM 
    Employees AS E
JOIN
    Persons AS P ON E.pid = P.pid
JOIN
    Facilities AS F ON E.fid = F.fid
LEFT JOIN
    Persons AS P_manager ON F.managerID = P_manager.pid
GROUP BY
    E.fid,
    F.address,
    F.city,
    F.province,
    F.postalCode,
    F.telephone,
    F.webAddress,
    F.type,
    F.capacity,
    P_manager.firstName,
    P_manager.lastName
ORDER BY
    F.province,
    F.city,
    F.type,
    numDoctors;
end $$

delimiter ;
call detailOfFacilitiesByRoles();


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
#lets say pid =4, startDate = '2024-03-24' and endDate= '2024-04-24'
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
	Employees AS E ON S.pid = E.pid
JOIN
	Facilities AS F ON S.fid= F.fid
WHERE
E.pid = given_pid
AND S.date> startDate AND S.date < endDate
ORDER BY
	F.name ASC,
	S.date ASC,
	S.startTime;
end $$

delimiter ;

call detailPersonScheduleInTimeFrame(4,'2024-03-24','2024-04-24');
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
#Let date = '2023-04-02'
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
	I.date AS infectionDate,
	F.name AS Facility_Name,
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
    	(SELECT pid, COUNT(*) AS numSecondaryResidences
     	FROM SecondaryLiving
     	GROUP BY pid
    	) AS SR ON E.pid = SR.pid
WHERE 
    	E.role = 'Doctor'
    	AND I.date >=DATE_SUB(specified_date, INTERVAL 2 WEEK)
        AND I.date <= (specified_date)

ORDER BY 
    	F.name ASC,
    	COALESCE(SR.numSecondaryResidences, 0) ASC;

end $$

delimiter ;
call detailDoctorsInfected('2023-04-02') ;
	
#13
#Let's say given_fid =1, start_date = 2024-24-03 and end_date = 2024-24-04
/*
For a given facility, list the emails generated for the cancellation of assignments during
a specific period of time. The results should be displayed in descending order by the
date of the emails.
*/

drop procedure if exists detailCancelledAppointmentsByFID;

delimiter $$
create procedure detailCancelledAppointmentsByFID(
	in given_fid int,
	in start_date DATE,
	in end_date DATE
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
WHERE 
    S.fid = given_pid
    AND S.date >= start_date
    AND S.date <= end_date
    AND S.isCanceled = 1
   
ORDER BY 
    S.scheduled_date DESC;

end $$

delimiter ;
call detailCancelledAppointmentsByFID(1,'2024-24-03','2024-24-04');

#14
#Let's say fid is 10 and specified_date is '2024-04-01'
/*
 For a given facility, generate a list of all the employees who have at least three
secondary residences and who have been on schedule to work in the last four weeks.
The list should include first-name, last-name, role, number of secondary residences.
Results should be displayed in ascending order by role, then by the number of
secondary residences
*/

drop procedure if exists detailSecondaryResidenceAndScheduled;

delimiter $$
create procedure detailSecondaryResidenceAndScheduled(
	in given_fid int,
	in specified_date DATE
)
begin
	
SELECT 
    P.firstName,
    P.lastName,
    E.role,
    (SELECT COUNT(DISTINCT SL.rid)
     FROM SecondaryLiving SL
     WHERE SL.pid = E.pid) AS numberOfSecondaryResidences
FROM 
    Employees E
JOIN 
    Persons P ON E.pid = P.pid
JOIN 
    Schedule S ON E.pid = S.pid
WHERE 
    E.fid = given_fid
    AND S.date BETWEEN DATE_SUB(specified_date, INTERVAL 4 WEEK) AND specified_date
GROUP BY 
    E.pid, E.role
HAVING 
    numberOfSecondaryResidences >= 3
ORDER BY 
    E.role ASC, 
    numberOfSecondaryResidences ASC;

end $$

delimiter ;
call detailSecondaryResidenceAndScheduled(10,'2024-04-01');
	
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
	COUNT(I.pid) AS numInfections,
	COUNT(V.pid) AS numVaccines,
	SUM(TIMESTAMPDIFF(HOUR, S.startTime, S.endTime)) AS total_hours_scheduled,
    	COALESCE(SR.numSecondaryResidences, 0) AS num_secondary_residences
FROM
 	Employees AS E1
JOIN
	Employees AS E2 ON E1.pid = E2.pid
JOIN 
	Infections AS I ON E1.pid = I.pid
JOIN
	Persons AS P ON E1.pid = P.pid
JOIN	
	Vaccines AS V ON E1.pid = V.pid
JOIN
	Schedule AS S ON E1.pid = S.pid
LEFT JOIN 
    	(SELECT pid, COUNT(*) AS numSecondaryResidences
     	FROM SecondaryLiving
     	GROUP BY pid
    	) AS SR ON P.pid = SR.pid
WHERE 
        	
			E1.endDate IS NULL
        	AND E2.endDate  IS NULL
        	AND E1.role = 'nurse'
        	AND E1.fid != E2.fid
            AND (I.type = 'COVID-19' OR I.type ='SARS-Cov-2 Variant' OR I.type = 'other types')
            AND I.date >= DATE_SUB(specified_date, INTERVAL 2 WEEK) AND I.date <= specified_date
GROUP BY
	P.pid	
ORDER BY
	E1.startDate ASC,
	P.firstName ASC,
	P.lastName ASC;
end $$

delimiter ;

#16	
 /*
Provide a report of all the employees working in all the facilities by role. Report should
include for every role of the employees, the total number of employees currently
working in the facilities, and the total number of employees currently infected by
COVID-19. Report should be displayed in ascending order by role
*/

drop procedure if exists detailEmployeeRolesInFacilities;

delimiter $$
create procedure detailEmployeeRolesInFacilities(
in specified_date
)
begin
	
SELECT 
    E.role,
    COUNT(DISTINCT E.pid) AS totalWorkingEmployees,
    SUM(
        CASE 
            WHEN I.pid IS NOT NULL AND I.date BETWEEN DATE_SUB(specified_date, INTERVAL 2 WEEK) AND specified_date THEN 1 
            ELSE 0 
        END
    ) AS totalInfectedByCovidNow
FROM 
    Employees E
LEFT JOIN 
    Infections I ON E.pid = I.pid
WHERE 
    E.endDate IS NULL 
GROUP BY 
    E.role
ORDER BY 
    E.role ASC;
end $$

delimiter ;
call detailEmployeeRolesInFacilities('2024-04-10')

#17
/*
Provide a report of all the employees working in all the facilities by role. Report should
include for every role of the employees, the total number of employees currently
working in the facilities, and the total number of employees who have never been
infected by COVID-19. Report should be displayed in ascending order by role.
*/
drop procedure if exists detailNeverInfected;

delimiter $$
create procedure detailNeverInfected()
begin	
SELECT 
    E.role,
    COUNT(DISTINCT E.pid) AS totalWorkingEmployees,
    COUNT(DISTINCT CASE WHEN NOT EXISTS (SELECT 1 FROM Infections I WHERE I.pid = E.pid) THEN E.pid END) AS neverInfectedByCovid
FROM 
    Employees E
WHERE 
    E.endDate IS NULL
GROUP BY 
    E.role
ORDER BY 
    E.role ASC;

delimiter ;
call detailNeverInfected();

#18
#let start_date be 2024-03-24 and end_date be 2024-03-25
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
    COUNT(DISTINCT F.fid) AS totalFacilities,
    COUNT(DISTINCT E.pid) AS totalWorkingEmployees,
    COUNT(DISTINCT CASE WHEN I.pid IS NOT NULL THEN I.pid END) AS totalInfectedEmployees, 
    SUM(DISTINCT F.capacity) AS totalFacilityCapacity,
    SUM(TIMESTAMPDIFF(HOUR, S.startTime, S.endTime)) AS totalScheduledHours 
FROM 
    Schedule S 
JOIN 
    Employees E ON S.pid = E.pid AND E.endDate IS NULL
LEFT JOIN 
    Infections I ON E.pid = I.pid AND I.date BETWEEN start_date AND end_date
JOIN 
    Facilities F ON F.fid = S.fid
WHERE 
    S.date BETWEEN start_date AND end_date
GROUP BY 
    F.province
ORDER BY 
    F.province ASC;
end $$

delimiter ;
call detailFacilitiesByProvince('2024-03-24','2024-03-25');


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

