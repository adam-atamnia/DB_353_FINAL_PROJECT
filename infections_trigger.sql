create trigger after_infections_insert
	after insert on Infections
	for each row
	delete from schedule s
		where 
			new.pid = s.pid and
			s.date >= new.date and
			s.date <= date_add(new.date, interval 2 week);

