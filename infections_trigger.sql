create trigger after_infections_insert
	after insert on Infections
	for each row
	delete from Schedule
		where 
			new.pid = pid and
			date >= new.date and
			date <= date_add(new.date, interval 2 week);

