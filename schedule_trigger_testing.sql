select * from Schedule;

select * from Employees where role = 'nurse' or role = 'doctor';

delete from Schedule where id > -1;

select * from Vaccines;
select * from Infections;

INSERT INTO Schedule (pid, fid, date, startTime, endTime) 
VALUES (63, 1, '2023-11-10', '19:21', '20:21');

update Infections
set type = 'COVID-19', date = '2023-11-02'
where pid = 63;

SELECT 
    *
FROM
    Schedule s1,
    Schedule s2
WHERE
    s1.date = s2.date AND s1.pid = s2.pid
		and s1.id < s2.id
        AND ((s1.startTime <= s2.startTime
        AND s1.endTime > s2.startTime)
        OR (s1.startTime < s2.endTime
        AND s1.endTime >= s2.endTime));
        
        
# find schedules on same day that are not 2h appart
SELECT 
	*
FROM
	Schedule s1,
	Schedule s2
WHERE
	s1.date = s2.date AND s1.pid = s2.pid
		and s1.id < s2.id
		AND (
			(s1.endTime > DATE_SUB(s2.startTime, INTERVAL 2 HOUR) and s1.endTime <= s2.startTime)
			OR 
			(s1.startTime < DATE_ADD(s2.endTime, INTERVAL 2 HOUR) and s1.startTime >= s2.endTime)
        );
	

# find schedule where no vaccine in the past 6 months
SELECT 
	*
FROM
	Schedule s
WHERE
	0 = (SELECT 
			COUNT(v.pid)
		FROM
			Vaccines v
		WHERE
			s.pid = v.pid
				AND v.date >= DATE_SUB(s.date, INTERVAL 6 MONTH));