#GRANT ALTER ON hkc353_4.Schedule TO 'hkc353_4'@'172.31.163.202';
drop table Schedule;
CREATE TABLE Schedule (
    pid INT,
    fid INT,
    date DATE,
    startTime TIME,
    endTime TIME,
    FOREIGN KEY (pid)
        REFERENCES Persons (pid),
    FOREIGN KEY (fid)
        REFERENCES Facilities (fid),
    
    # I added this field for the purpose of differentiating the entries so I can delete them in a trigger if they are violating the constraints
    id int auto_increment primary key
);

INSERT INTO Schedule (pid, fid, date, startTime, endTime) 
VALUES
(1, 1, '2024-05-05', '02:21', '07:21');
