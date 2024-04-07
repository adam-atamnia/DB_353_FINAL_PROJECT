delimiter $$

create trigger after_schedule_insert
after insert on Schedule
for each row
begin


	if 
    (new.startTime < new.endTime)
    or (0 = (SELECT 
            COUNT(s1.pid)
        FROM
            Schedule s1,
            Schedule s2
        WHERE
            s1.date = s2.date AND s1.pid = s2.pid
                AND (s1.startTime <= s2.startTime
                AND s1.endTime > s2.startTime)
                OR (s1.startTime < s2.endTime
                AND s1.endTime >= s2.endTime)))
    or (0 = (SELECT 
            COUNT(s1.pid)
        FROM
            Schedule s1,
            Schedule s2
        WHERE
            s1.date = s2.date AND s1.pid = s2.pid
                AND s1.endTime > DATE_SUB(s2.startTime, INTERVAL 2 HOUR)
                OR s1.startTime < DATE_ADD(s2.endTime, INTERVAL 2 HOUR)))
    or (0 = (SELECT 
            COUNT(s.pid)
        FROM
            Schedule s,
            Employees e,
            Infections i
        WHERE
            s.pid = e.pid AND s.pid = i.pid
                AND i.type = 'COVID-19'
                AND (e.role = 'nurse' OR e.role = 'doctor')
                AND s.date >= i.date
                AND s.date <= DATE_ADD(i.date, INTERVAL 1 WEEK)))
    or (0 = (SELECT 
            COUNT(s.pid)
        FROM
            Schedule s
        WHERE
            0 = (SELECT 
                    COUNT(v.pid)
                FROM
                    Vaccines v
                WHERE
                    s.pid = v.pid
                        AND v.date >= DATE_SUB(s.date, INTERVAL 6 MONTH))))
	then
		delete from schedule s
			where new.created_at = s.created_at;
	

	end if;

end$$

delimiter ;

