drop trigger if exists after_infections_insert;

create trigger after_infections_insert
	after insert on Infections
	for each row
	update Schedule
		set isCanceled = true
		where 
			new.pid = pid and
			date >= new.date and
			date <= date_add(new.date, interval 2 week);