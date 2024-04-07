# 11 
# lets say person id is 1
/*
 For a given employee, get the details of all the people who live with the employee at 
the primary address and at all the secondary addresses. For every address the employee 
has, you need to provide the residence type for that address, and for every person who 
lives at that address, you need to provide the person’s first name, last name, occupation 
of the person, and the relationship with the employee.
*/

#get all info about people who live together

select *
	from PrimaryLiving p, SecondaryLiving s, Residences r
    where 
		p.pid = 1 and s.pid = 1 # lets say person id is 1
        and (r.rid = p.rid or r.rid = s.pid)
    


