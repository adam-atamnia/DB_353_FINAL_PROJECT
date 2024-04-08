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

# -------------- 15 by adam
        
/*

 Get details of nurses who are currently working at two or more different facilities and 
have been infected by COVID-19 in the last two weeks. Details include first-name, 
last-name, first day of work as a nurse, date of birth, email address, total number of 
times the nurse got infected by COVID-19, total number of vaccines the nurse had, 
total number of hours scheduled, and total number of secondary residences. Results 
should be displayed sorted in ascending order by first day of work, then by first name, 
then by last name.

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
    


