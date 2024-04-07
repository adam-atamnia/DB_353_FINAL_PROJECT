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
        
    


