drop trigger before_schedule_insert;

delimiter $$

create trigger before_schedule_insert
before insert on Schedule
for each row
begin
	
    declare isInsertValid boolean;
    declare message varchar(100);
    
    set isInsertValid = true;
    set message = '???';

	if (new.startTime >= new.endTime) then # Start time cannot be greater than the end time.
		set isInsertValid = false;
		set message = 'Start time has to be smaller than end time.';
    elseif (0 != (
		# find schedules that conflict
		SELECT 
            COUNT(*)
        FROM
			Schedule s2
		WHERE
			new.date = s2.date AND new.pid = s2.pid
				AND ((new.startTime <= s2.startTime
				AND new.endTime > s2.startTime)
				OR (new.startTime < s2.endTime
				AND new.endTime >= s2.endTime))
			)
		)
	then
		set isInsertValid = false;
		set message = 'Schedules should not conflict.';
    elseif (0 != (
		# find schedules on same day that are not 2h appart
		SELECT 
            COUNT(*)
        FROM
            Schedule s2
        WHERE
            new.date = s2.date AND new.pid = s2.pid
                AND (
					(new.endTime > DATE_SUB(s2.startTime, INTERVAL 2 HOUR) and new.endTime <= s2.startTime)
					OR 
					(new.startTime < DATE_ADD(s2.endTime, INTERVAL 2 HOUR) and new.startTime >= s2.endTime)
				)
			)
		)
    then
		set isInsertValid = false;
		set message = 'Schedules on the same day for the same person should be 2 hours appart.';
    elseif (
		0 != (
		# find infections where new schedule is during 2 weeks after it
		select count(*)
		from Employees e, Infections i
		where 
			new.pid = e.pid and
			new.pid = i.pid and 
			i.type = 'COVID-19' and
			(e.role = 'nurse' or e.role = 'doctor') and
			new.date >= i.date and
			new.date <= date_add(i.date, interval 2 week)
			)
		)
	then
		set isInsertValid = false;
		set message = 'Cannot schedule employee during 2 weeks after infection by COVID-19.';
    elseif (0 = (
				# find number of vaccines in past 6 months
				SELECT 
                    COUNT(*)
                FROM
                    Vaccines
                WHERE
                    new.pid = pid
					AND date >= DATE_SUB(new.date, INTERVAL 6 MONTH)
                    AND date <= new.date
				)
			)
	then
		set isInsertValid = false;
		set message = 'Cannot schedule employee if they had no vaccines in the past 6 months.';
        
	end if;
    
    if isInsertValid = false then
		#set message = concat('ID: ', new.id, ' - ', message);
		signal sqlstate '45000' set message_text = message;
	end if;

end$$

delimiter ;

