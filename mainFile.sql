-- VEHICLE MAINTENANCE DATABASE SYSTEM

-- NOTES: 

-- CREATING DATABASE
CREATE DATABASE VMDBS;

-- USING THE DATABASE
USE VMDBS;


-- CREATE TABLE STATEMENTS (DDL):

-- 1.CREATING customer table
CREATE TABLE customer(
customer_ID INT AUTO_INCREMENT,
customer_name VARCHAR(50) NOT NULL, 
contact_number BIGINT NOT NULL,
DOB DATE NOT NULL,
address VARCHAR (1000) NOT NULL,
emailID VARCHAR(25) NOT NULL,
PRIMARY KEY(customer_ID)
);


-- 2.CREATING team table
CREATE TABLE team(
team_ID INT AUTO_INCREMENT ,
team_name VARCHAR(30) NOT NULL,
bay_no INT,
mng_start_date DATE NOT NULL,
PRIMARY KEY(team_ID)
);


-- 3.CREATING employee table
CREATE TABLE employee(
emp_ID INT AUTO_INCREMENT UNIQUE,
emp_name VARCHAR(30) NOT NULL,
team_ID INT ,
DOB DATE NOT NULL,
sex VARCHAR(10) NOT NULL,
mng_ID INT,
hourly_pay DECIMAL(10,2) NOT NULL,
ann_salary DECIMAL(10,2),
email_ID VARCHAR(50) NOT NULL,
phone_NO BIGINT NOT NULL,
PRIMARY KEY(emp_ID),
FOREIGN KEY (team_ID) REFERENCES team (team_ID) ON DELETE SET NULL ON UPDATE CASCADE,
FOREIGN KEY (mng_ID) REFERENCES employee (emp_ID)ON DELETE SET NULL ON UPDATE CASCADE
);



-- 4.CREATING parts table
CREATE TABLE parts(
part_ID INT AUTO_INCREMENT ,
part_Name VARCHAR(25) NOT NULL,
part_description VARCHAR(100) ,
manufacturer VARCHAR(25) ,
purchase_date DATE NOT NULL,
purchase_price DECIMAL(10,2),
quantity INT,
total_price DECIMAL(10,2),
PRIMARY KEY (part_ID)
);


-- 5.CREATING vehicles table
CREATE TABLE vehicles(
vehicle_ID INT AUTO_INCREMENT ,
customer_ID INT,
vehicle_Name VARCHAR(25) NOT NULL,
reg_NO VARCHAR(25) UNIQUE,
VIN VARCHAR(25) UNIQUE,
color VARCHAR(25),
model VARCHAR(25) DEFAULT 'BASIC VARIANT',
pur_year YEAR,
kms_driven DECIMAL(7,1),
prev_service DATE,
prev_service_des VARCHAR(100),
fuel_level VARCHAR(25) DEFAULT 'EMPTY',
PRIMARY KEY(vehicle_ID),
FOREIGN KEY (customer_ID) REFERENCES customer(customer_ID) ON DELETE SET NULL ON UPDATE CASCADE
);

-- 6.Creating maintenance record table
CREATE TABLE record(
record_ID INT AUTO_INCREMENT ,
vehicle_ID INT,
customer_ID INT,
service_type VARCHAR(100) DEFAULT 'FREE SERVICE',
date DATE,
time TIME,
service_cost DECIMAL(10,2),
material_cost DECIMAL(10,2),
odometer_reading DECIMAL(7,1),
customer_requirements VARCHAR(100),
description VARCHAR(100),
delivery_date DATE,
PRIMARY KEY(record_ID),
FOREIGN KEY (vehicle_ID) REFERENCES vehicles (vehicle_ID) ON DELETE SET NULL ON UPDATE CASCADE,
FOREIGN KEY (customer_ID) REFERENCES customer (customer_ID) ON DELETE SET NULL ON UPDATE CASCADE
);

-- 7.Creating Payments table
CREATE TABLE payment(
payment_ID INT AUTO_INCREMENT,
customer_ID INT,
vehicle_ID INT,
record_ID INT,
invoice_ID VARCHAR(25) NOT NULL,
payment_date DATE,
total_amount DECIMAL(10,2),
payment_status ENUM('PAID','PENDING'),
mode_of_payment VARCHAR(50) DEFAULT'CASH',
PRIMARY KEY (payment_ID),
FOREIGN KEY (vehicle_ID) REFERENCES vehicles (vehicle_ID) ON DELETE SET NULL ON UPDATE CASCADE,
FOREIGN KEY (customer_ID) REFERENCES customer (customer_ID) ON DELETE SET NULL ON UPDATE CASCADE,
FOREIGN KEY (record_ID) REFERENCES record(record_ID) ON DELETE SET NULL ON UPDATE CASCADE
);


-- 8.Creating departments table
CREATE TABLE departments(
mng_ID INT,
team_ID INT,
FOREIGN KEY(mng_ID) REFERENCES employee (emp_ID) ON DELETE SET NULL ON UPDATE CASCADE,
FOREIGN KEY(team_ID) REFERENCES team (team_ID) ON DELETE SET NULL ON UPDATE CASCADE
);


-- 9.Creating used table
CREATE TABLE used(
record_ID INT,
vehicle_ID INT,
team_ID INT,
part_ID INT ,
quantity INT NOT NULL,
FOREIGN KEY (record_ID) REFERENCES record(record_ID) ON DELETE SET NULL ON UPDATE CASCADE,
FOREIGN KEY (vehicle_ID) REFERENCES vehicles(vehicle_ID) ON DELETE SET NULL ON UPDATE CASCADE,
FOREIGN KEY (team_ID) REFERENCES team(team_ID) ON DELETE SET NULL ON UPDATE CASCADE,
FOREIGN KEY (part_ID) REFERENCES parts(part_ID) ON DELETE SET NULL ON UPDATE CASCADE
);

-- TRIGGERS

-- 1.TRIGGER TO calculate annual salary of each employee from hourly salary
CREATE TRIGGER before_hourly_pay_insert
BEFORE INSERT ON employee
FOR EACH ROW
SET NEW.ann_salary=(NEW.hourly_pay*2184);

-- 2.CREATE TRIGGER Update Annual Salary on hourly pay update
DELIMITER //

CREATE TRIGGER before_hourly_pay_update
BEFORE UPDATE ON employee
FOR EACH ROW
SET NEW.ann_salary = NEW.ann_salary + ((NEW.hourly_pay - OLD.hourly_pay) * 2184);

//

DELIMITER ;


-- 3.Trigger for calculating the total_price of each item purchased
CREATE TRIGGER before_part_insert
BEFORE INSERT ON parts
FOR EACH ROW
SET NEW.total_price=(NEW.purchase_price*NEW.quantity);


-- 4.Trigger to update stock quantity when the quantity of item falls below 10 by 100

DELIMITER //

CREATE TRIGGER update_stock_when_low
BEFORE UPDATE ON parts
FOR EACH ROW
BEGIN
    IF NEW.quantity < 10 THEN
        SET NEW.quantity = NEW.quantity + 100;
    END IF;
END;

//

DELIMITER ;


-- 5.Trigger to copy the kms_driven to odometer reading on INSERT
CREATE TRIGGER odo_reading
BEFORE INSERT ON record
FOR EACH ROW 
SET NEW.odometer_reading= (SELECT kms_driven FROM vehicles WHERE NEW.vehicle_ID=vehicles.vehicle_ID);

-- 6.Trigger to copy the kms_driven to odometer reading on UPDATE
DELIMITER //

CREATE TRIGGER odo_reading_before_update
BEFORE UPDATE ON record
FOR EACH ROW 
SET NEW.odometer_reading = (SELECT kms_driven FROM vehicles WHERE NEW.vehicle_ID = vehicles.vehicle_ID);

//

DELIMITER ;


-- 7.Trigger to update the inventory parts when a part is used:
CREATE TRIGGER stock_update
AFTER INSERT ON used
FOR EACH ROW 
UPDATE parts SET quantity=quantity-NEW.quantity
WHERE parts.part_ID=NEW.part_ID; 

-- 8.TRIGGER to generate the amount paid by customer 18%on service cost + 28%on parts price
CREATE TRIGGER total_amt_paid
BEFORE INSERT ON payment
FOR EACH ROW
SET NEW.total_amount=(((SELECT service_cost FROM record AS M WHERE NEW.record_ID=M.record_ID)*1.18)+((SELECT material_cost FROM record AS M WHERE NEW.record_ID=M.record_ID)*1.18));

-- 9.Trigger to update previous service date in vehicle table to present service date from record on completion of service {AFTER INSERT IN record table}
DELIMITER //

CREATE TRIGGER update_prev_date
AFTER INSERT ON record
FOR EACH ROW
BEGIN
    UPDATE vehicles
    SET prev_service = (
        SELECT MAX(delivery_date)
        FROM record
        WHERE vehicle_ID = NEW.vehicle_ID
    )
    WHERE vehicle_ID = NEW.vehicle_ID;
END;

//

DELIMITER ;

-- 10.Trigger to update the part total price after the part is used 
CREATE TRIGGER total_price
BEFORE UPDATE ON parts
FOR EACH ROW 
SET NEW.total_price=NEW.quantity*NEW.purchase_price;

-- INSERT STATEMENTS

INSERT INTO customer
VALUES
(NULL,'Adithya Deepthi Kumar',7022378358,'2003-10-17','#220,8th Cross Srirampura 2nd Stage,Mysore','adithya@gmail.com'),
(NULL,'Avinash S Dixit',9663527452,'2003-03-13','#50,15th Cross LIG Colony Kuvempunagar','avinashdixit@gmail.com'),
(NULL,'Harsha N P',7760307519,'2003-04-10','#1399 2nd Floor,SJCE Road, Mysore','harshanp603@gmail.com'),
(NULL,'Rohan  I N',9785241057,'2002-12-30','#247, 17th Cross, RMP Layout, Vijayanagar 3rd Stage, Mysuru','rohanin@gmail.com'),
(NULL,'Vishnu Charan',9553401157,'2003-11-11','#221, 10th cross, KHB colony, Belwadi,Mysore','vishucharan@gmail.com'),
(NULL,'Mohan Rao',9638754428,'1995-06-15','#20, 10th Cross, 2nd main, Saraswathipuram, Mysore','raomohan@gmail.com'),
(NULL,'Rupesh J',9885236647,'1993-07-02','#225, 2nd Cross, 18th main , Vijayanagar 2nd Stage, Mysore','rupeesh@gmail.com'),
(NULL,'Mohith C',7558632214,'1990-08-20','#85, 5th Cross, 2nd Main , 1st Stage Vijayanagar,Mysore','mohith@gamil.com');


INSERT INTO team
VALUES
(NULL,'Engine Team',1,'2010-04-01'),
(NULL,'Electrical Team',5,'2019-10-01'),
(NULL,'Tire & Brake Team',3,'2007-08-01'),
(NULL,'Chassis & Wash Team',2,'2013-12-01'),
(NULL,'Finance & Sales Team',NULL,'2003-05-01'),
(NULL,'Administration',NULL,'2000-06-01');
			 

INSERT INTO employee
VALUES
(NULL,'Srinivas',6,'1970-10-10','Male',NULL,300,NULL,'srinivas1970@gmail.com','9887452214'),
(NULL,'Vinay',5,'1975-02-08','Male',1,250,NULL,'vinay@gmail.com','9774526680'),
(NULL,'Rakesh',1,'1980-10-15','Male',1,220,NULL,'rakesh@gmail.com','9663254471'),
(NULL,'Deepak',2,'1983-07-25','Male',1,200,NULL,'deepak@gmail.com','9887501124'),
(NULL,'Sathish',3,'1981-04-12','Male',1,200,NULL,'sathish81@gmail.com','8557412245'),
(NULL,'Naveen',4,'1985-07-07','Male',1,200,NULL,'Naveen07@gmail.com','8554569632');

INSERT INTO departments
VALUES
(1,6),
(2,5),
(2,1),
(4,2),
(5,3),
(6,4);


INSERT INTO parts
VALUES
(NULL,'Brake Pads', 'Front brake pads for 2-wheelers', 'Hero MotoCorp', '2023-01-15', 2500, 100,NULL),
(NULL,'Spark Plug', 'High-performance spark plug', 'Bajaj Auto', '2022-11-05', 200, 150,NULL),
(NULL,'Oil Filter', 'Premium oil filter for 2-wheelers', 'Suzuki', '2022-12-10', 500, 150,NULL),
(NULL,'Tire', 'Rear tire for 2-wheelers', 'TVS', '2023-02-20', 3000, 500,NULL),
(NULL,'Chain Kit', 'Heavy-duty chain kit', 'Hero MotoCorp', '2022-10-08', 1000, 200,NULL),
(NULL,'Battery', 'Maintenance-free battery', 'Bajaj Auto', '2022-09-15', 2000, 50,NULL),
(NULL,'Air Filter', 'High-flow air filter', 'TVS', '2022-12-28', 750, 180,NULL),
(NULL,'Headlight Bulb', 'LED headlight bulb', 'Suzuki', '2023-03-10', 1500, 250,NULL),
(NULL,'Brake Fluid', 'Premium brake fluid', 'Hero MotoCorp', '2023-04-05', 280, 100,NULL),
(NULL,'Handle Grips', 'Comfortable handle grips', 'TVS', '2022-11-20', 120, 300,NULL),
(NULL,'Exhaust System', 'Performance exhaust system', 'Suzuki', '2023-05-12', 6000, 70,NULL),
(NULL,'Clutch Cable', 'Durable clutch cable', 'Hero MotoCorp', '2023-02-28', 1000, 1500,NULL),
(NULL,'Mirror Set', 'Rearview mirror set for 2-wheelers', 'Bajaj Auto', '2022-11-15', 700, 50,NULL),
(NULL,'Seat Cover', 'Comfortable seat cover','TVS','2023-04-12', 800, 80,NULL),
(NULL,'Chain Lubricant', 'High-performance chain lubricant', 'Hero MotoCorp', '2022-12-15', 90, 2000,NULL),
(NULL,'Gasket Kit', 'Complete gasket kit for engine maintenance', 'Bajaj Auto', '2023-01-30', 180, 100,NULL),
(NULL,'Brake Lever', 'Adjustable brake lever', 'Hero MotoCorp', '2022-10-18', 800, 1200,NULL),
(NULL,'Fork Oil', 'Premium fork oil for suspension', 'Hero MotoCorp', '2023-04-10', 150, 1000,NULL),
(NULL,'Throttle Cable', 'Smooth throttle cable for 2-wheelers', 'TVS', '2022-09-30', 250, 150,NULL),
(NULL,'Radiator Coolant', 'High-quality radiator coolant', 'Hero MotoCorp', '2023-06-05', 50, 1000,NULL),
(NULL,'Engine Oil', 'High-quality Engine Oil', 'Hero MotoCorp', '2023-01-10', 300, 1000,NULL);



-- To Check the working of Trigger
UPDATE parts
SET quantity=50
WHERE part_id=13;

-- INSERT INTO vehicles
INSERT INTO Vehicles
(vehicle_ID,customer_ID,vehicle_Name,reg_NO,VIN,color,model,pur_year,kms_driven,prev_service,prev_service_des,fuel_level)
VALUES
(NULL,1,"XPULSE","KA-09-AH-6055","JYA2UJE0X2A050036","Black","Hero Xpulse 2V",2022,3000,"2023-01-01","Water Wash,Oil change","M"),
(NULL,2,"JUPITER","KA-09-AA-8055","YJA3VKF1Y3B161147","Blue","TVS Jupiter ZX",2021,3500,"2023-10-05","Water Wash,Oil change,Replaced Spark Plug","F"),
(NULL,3,"PULSAR","KA-55-HU-0735","KZB4WLH2Y4C273358","Silver","Bajaj Pulsar ns 200",2023,750,NULL,NULL,"E"),
(NULL,4,"DUKE","TN-11-BN-0777","LAC5YMI3Z5D384469","Orange","KTM Duke 250",2023,1500,"2023-04-01","Oil Change,Chain Cleaning","M"),
(NULL,5,"R15","PY-01-ME-0505","MBD6ZNJ4A6E495570","Red","Yamaha R15 V4",2022,5000,"2022-12-31","Replaced Spark Plug,Chain Replaced","E"),
(NULL,6,"Activa","HR-26-DQ-0111","NCE7AMK5B7F506681","Green","Honda Activa Premium",2023,4500,"2022-09-28","Changed Break Pads","M"),
(NULL,7,"Ninja","MH-12-BB-1234","ODF8BNL6C8G617792","Lime Green","Kawasaki Ninja 300",2020,5500,"2023-06-30","Changed Break Pads,Water wash,Clutch changed,oil change","F"),
(NULL,8,"Himalayan","KL-01-AD-1010","PEG9COM7D9H728801","Dualtone blue white","Royal Enfield Himalayan",2021,8500,"2023-02-14","Chain Replaced,Oil change,New Mirrors,Suspension Adjustment","E");



-- INSERT INTO Maintenance Record
INSERT INTO record
(record_ID,vehicle_ID,customer_ID,service_type,date,time,service_cost,material_cost,odometer_reading,customer_requirements,description,delivery_date)
VALUES
(NULL,1,1,"Free Service","2023-04-15","10:15:00",0,326,NULL,"Full inspection and testride",'Engine Oil Change',"2023-04-15"),
(NULL,2,2,"Paid Service","2023-09-20","17:45:23",350,3500,NULL,"Battery change and sparkplug change",'Battery and Spark plug changed',"2023-09-21"),
(NULL,3,3,"Free Service","2023-02-14","10:15:00",0,0,NULL,"No N2 filling,water wash,polishing",'No Issues',"2023-02-15"),
(NULL,4,4,"Paid Service","2023-10-15","12:15:00",150,200,NULL,"suspension inspect,change brake pads",'Break Pads Changes',"2023-10-16"),
(NULL,5,5,"Paid Service","2023-11-29","11:45:00",250,1200,NULL,"verify odometer settings,chain replacement",'Odometer Recalibrated & Chain Changed',"2023-11-30"),
(NULL,6,6,"Paid Service","2023-06-29","13:25:00",150,0,NULL,"seat cover adjustment,n2 filling,break pad adjustment",'No Issues',"2023-06-30"),
(NULL,7,7,"Paid Service","2023-11-30","11:55:00",300,200,NULL,"Full inspection,throttle inspection",'Engine Oil & Gear Cable Changed',"2023-12-04"),
(NULL,8,8,"Paid Service","2023-12-01","16:20:00",200,0,NULL,"Suspension inspection,Odometer checking",'Suspension and Breaks Calibrated',"2023-12-04");


-- INSERT into used
INSERT INTO used
VALUES
(1,1,1,21,1);


-- INSERT INTO paymnent
INSERT INTO payment
VALUES
(NULL,1,1,1,'INV-23-04-15-1','2023-04-15',NULL,'PAID','CASH');

-- Inserting employees into the database:
INSERT INTO employee
VALUES
(NULL, 'Nagraj', 1, '1988-08-20', 'Male', 3, 190, NULL, 'nagraj@gmail.com', '9887654321'),
(NULL, 'Rajesh', 1, '1982-03-15', 'Male', 3, 190, NULL, 'rajesh82@gmail.com', '9778965412'),
(NULL, 'Kiran Kumar', 1, '1977-05-18', 'Male', 3, 200, NULL, 'kiran@gmail.com', '9663258741'),
(NULL, 'Amit', 1, '1995-11-30', 'Male', 3, 150, NULL, 'amit@gmail.com', '9887456321'),
(NULL, 'Pradeep', 2, '1984-09-02', 'Male', 4, 180, NULL, 'pradeep@gmail.com', '8557896543'),
(NULL, 'Ramesh', 2, '1988-09-22', 'Male', 4, 180, NULL, 'ramesh@gmail.com', '8667896993'),
(NULL, 'Sagar', 2, '1990-05-12', 'Male', 4, 170, NULL, 'sagar@gmail.com', '9552102247'),
(NULL, 'Harish', 3, '1988-10-02', 'Male', 5, 180, NULL, 'harish@gmail.com', '7885421102'),
(NULL, 'Manjunath', 3, '1992-04-18', 'Male', 5, 180, NULL, 'manjunath@gmail.com', '9663254410'),
(NULL, 'Swami', 3, '1984-07-08', 'Male', 5, 180, NULL, 'swami@gmail.com', '9551024475'),
(NULL, 'Gopal', 4, '1997-02-10', 'Male', 6, 150, NULL, 'gopal@gmail.com', '9557896557'),
(NULL, 'Ganesh', 4, '1995-09-27', 'Male', 6, 150, NULL, 'ganesh@gmail.com', '9125475437'),
(NULL, 'Ajith', 4, '1998-06-12', 'Male', 6, 130, NULL, 'ajith07@gmail.com', '7254185288'),
(NULL, 'Sneha', 5, '1990-06-25', 'Female', 2, 200, NULL, 'sneha@gmail.com', '9778541236'),
(NULL, 'Anita', 5, '1987-12-10', 'Female', 2, 200, NULL, 'anita@gmail.com', '9663214789'),
(NULL, 'Priya', 6, '1990-04-05', 'Female', 1, 200, NULL, 'priya@gmail.com', '9887543201');

-- Inserting more customers into database
INSERT INTO customer
VALUES
(9,'Dinesh Kumpar',9965412340,'1991-04-01','#95 2nd cross Devraj Mohalla','dineshkumar65@gmail.com'),
(10,'Prasad Shetty',7892514331,'1992-04-10','#306 3rd main Siddartha Layout','prasadshetty69@gmail.com'),
(11,'Naman',6365412890,'2003-01-01','#105 10th cross RP Road,Nanjangud ','namanjain@gmail.com'),
(12,'Shreyas Herale',8147711454,'2004-01-18','#112 8th main road ,Vijayanagar 3rd stage','heraleshreyas@gmail.com'),
(13,'Eshwar J',7019413068,'2003-09-15','#35 1st main road Shivmogga','eshwar65@gmail.com'),
(14,'Ganesh Sharma',7730604826,'1999-10-10','#78 3rd cross M block Kuvempunagar','ganeshsharma001@gmail.com'),
(15,'Sandesh Kumar',9874563210,'2001-12-31','#88 1st main road Bogadi 2nd stage','sandeshkumar45@gmail.com');


-- Inserting into vehicels
INSERT INTO vehicles
VALUES
(NULL,9,"Shine","KA-08-ES-6478","QFH0DPN8E0I839912","Black","Honda Shine 150",2023,750,NULL,NULL,"F"),
(NULL,10,"Splendor +","HR-28-MW-1598","RGI1EQO9FJ940023","Blue","Hero Splendor +",2015,50000,"2023-08-08","Changed front and rear tyres","E"),
(NULL,11,"Meteor 350","KA-09-JK-0973","SHJ2FR10GK051134","Dual tone RED and Black","Royal Enfield Meteor",2022,8500,"2023-05-15","Changed Tyre tubes,Water wash,polish","M"),
(NULL,12,"RC 250","TN-10-DK-4444","TIK3GS21HL162245","Black","KTM RC 250",2023,2525,"2023-06-14","Break Pad replacement ,seat adjustment,mirror replacement","E"),
(NULL,13,"Appache","KL-26-ML-0231","UJL4HT32IM273356","Grey","TVS Appache RTR 150",2017,65000,"2022-09-15","Engine oil changed,tyres changed,clutch adjustment","M"),
(NULL,14,"MT 15","KA-01-FG-4564","VKM5IU43JN384467","Blue","Yamaha MT 15",2022,15000,"2023-03-15","Water wash,polish,N2 filing","E"),
(NULL,15,"Bobber","KA-09-JI-1111","WLN6JV54KO495578","White","Jawa Bobber",2023,4500,"2023-09-17","seat adjustment,lamp adjustment,water wash","F");


-- Inserting records into database
INSERT INTO record
VALUES
(NULL,9,9,"Free Service","2023-05-10","9:25:00",0,200,NULL,"N2 filling,Seat adjustment,lubricate chain",'Seat cover adjusted,N2 filled and chain lubricated',"2023-05-10"),
(NULL,10,10,"Paid Service","2023-06-10","10:25:00",500,3300,NULL,"Break pads change,sparkplug change,inspect oil filter",'break pads,sparkplug and oil filter changed',"2023-06-11"),
(NULL,11,11,"Paid Service","2023-07-10","11:25:00",200,550,NULL,"Change Tire tubes ,Inspect exhaust",'Tyre tube changed and puncher fixed, exhaust recalibrated',"2023-07-11"),
(NULL,12,12,"Paid Service","2023-08-10","12:25:00",200,100,NULL,"N2 filling,Clutch Adjustment,brake adjustment,Chain lubrication",'Clutch adjusted and chain lubricated',"2023-08-10"),
(NULL,13,13,"Paid Service","2023-09-10","13:25:00",800,7800,NULL,"Oil filter replacement,Change front and rear tyres,Replace chains",'Oil filter,front and rear tyres,chain replaced',"2023-09-12"),
(NULL,14,14,"Paid Service","2023-10-10","14:25:00",400,3500,NULL,"Brake pads change,spark plug change,battery recharge,air filter change",'Brake pads,spark plug ,air filter changed and battery recharged',"2023-10-12"),
(NULL,15,15,"Paid Service","2023-11-10","15:30:00",150,200,NULL,"N2 filling,mirror adjustment,chain lubrication",'N2 filled and mirror adjusted and chain lubricated',"2023-11-10");

-- Inserting into parts
INSERT INTO parts
VALUE(NULL,'Tyre tube', 'High-quality Tube', 'Hero MotoCorp', '2022-06-25', 350, 1000,NULL);

INSERT INTO parts
VALUE(NULL,'Susoension Unit', 'High-quality Tube', 'Hero MotoCorp', '2022-06-25', 4000, 250,NULL);


INSERT INTO used
VALUES
(2,2,2,6,1),
(2,2,2,2,1),
(4,4,3,1,2),
(5,5,1,5,1),
(6,6,3,1,2),
(7,7,1,21,1),
(7,7,1,12,1),
(8,8,3,23,1),
(9,9,3,15,1),
(10,10,2,1,2),
(11,11,3,22,1),
(12,12,3,15,1),
(13,13,1,3,1),
(14,14,3,1,1);

-- INSERT INTO paymnet
INSERT INTO payment
VALUES
(NULL,2,2,2,'INV-23-09-21-1','2023-09-21',NULL,'PAID','UPI'),
(NULL,3,3,3,'INV-23-02-15-1','2023-02-15',NULL,'PAID','CHEQUE'),
(NULL,4,4,4,'INV-23-10-17-1','2023-10-17',NULL,'PAID','UPI'),
(NULL,5,5,5,'INV-23-12-02-1','2023-12-02',NULL,'PAID','CASH'),
(NULL,6,6,6,'INV-23-07-05-1','2023-07-05',NULL,'PAID','UPI'),
(NULL,7,7,7,'INV-23-12-04-1','2023-12-04',NULL,'PAID','CASH'),
(NULL,8,8,8,'INV-23-12-04-1','2023-12-04',NULL,'PAID','UPI'),
(NULL,9,9,9,'INV-23-05-12-1','2023-05-12',NULL,'PAID','UPI'),
(NULL,10,10,10,'INV-23-06-11-1','2023-06-11',NULL,'PAID','CASH'),
(NULL,11,11,11,'INV-23-07-15-1','2023-07-15',NULL,'PAID','UPI'),
(NULL,12,12,12,'INV-23-08-11-1','2023-08-11',NULL,'PAID','CASH'),
(NULL,13,13,13,'INV-23-09-12-1','2023-09-12',NULL,'PAID','UPI'),
(NULL,14,14,14,'INV-23-10-12-1','2023-10-12',NULL,'PAID','UPI'),
(NULL,15,15,15,'INV-23-10-12-1','2023-10-12',NULL,'PAID','CASH');


-- Inseting data into PARTS table
INSERT INTO parts
VALUES 
(NULL,'Automobile Paint', 'Matte and Glossy Paint', 'TVS', '2023-8-10', 350, 300,NULL),
(NULL,'Foam Wash Liquid', 'Best Quality Foaming liquid', 'TVS', '2023-09-10', 200, 1000,NULL),
(NULL,'Automoblie Wax', 'Glossy Finish wax', 'Suzuki', '2023-05-10', 375, 1000,NULL);

-- Inserting data into record
INSERT INTO record
VALUES
(NULL,1,1,"Paid Service","2023-12-01","9:25:00",600,800,NULL,"Wash ,Scratch removal",'Washed and piloshed',"2023-12-01"),
(NULL,2,2,"Paid Service","2023-11-28","10:25:00",700,1300,NULL,"Wash, dent fix and polish",'Washed , polished and body fix',"2023-11-30"),
(NULL,3,3,"Paid Service","2023-10-30","11:25:00",2000,5500,NULL,"Accident repair",'Paint patchup ,body fix and polished',"2023-11-04"),
(NULL,4,4,"Paid Service","2023-11-15","12:25:00",200,100,NULL,"Body dent and paint",'Paint job and polish',"2023-10-18"),
(NULL,5,5,"Paid Service","2023-09-10","13:25:00",50,250,NULL,"Wash",'Washed',"2023-09-12"),
(NULL,6,6,"Paid Service","2023-10-10","14:25:00",100,1000,NULL,"Full polish wash",'Deep cleaned and polished',"2023-10-12");

-- Inserting into used
INSERT INTO used
VALUES
(16,1,4,25,1),
(17,1,4,24,1),
(18,1,4,24,1),
(19,1,4,26,1),
(20,1,4,25,1),
(21,1,4,26,1);

-- INSERT INTO paymnet
INSERT INTO payment
VALUES
(NULL,1,1,16,'INV-23-12-01-6','2023-09-21',NULL,'PAID','UPI'),
(NULL,2,2,17,'INV-23-12-01-5','2023-02-15',NULL,'PAID','CHEQUE'),
(NULL,3,3,18,'INV-23-10-15-8','2023-10-17',NULL,'PAID','UPI'),
(NULL,4,4,19,'INV-23-9-15-15','2023-07-05',NULL,'PAID','UPI'),
(NULL,5,5,20,'INV-23-10-15-2','2023-12-04',NULL,'PAID','CASH'),
(NULL,6,6,21,'INV-23-10-15-17','2023-12-04',NULL,'PAID','UPI');

-- CREATING VIEWS

-- Total number of vehicle requests serviced by each team
CREATE VIEW Service_Count AS
SELECT used.team_ID,team_name,COUNT(*) AS'Service Count' 
FROM used,team
WHERE used.team_ID=team.team_ID
GROUP BY (used.team_ID);

SELECT * FROM Service_Count;

-- 2>Creating a view maintaince record along with the record info name of the vehicle and customer name
CREATE VIEW Maintenance_Record
AS
SELECT vehicle_name,customer_name,R.*
FROM record AS R
JOIN vehicles AS V USING(vehicle_ID)
JOIN customer AS C ON R.customer_ID=C.customer_ID;

SELECT * FROM Maintenance_Record;

-- 3>Creating a view of payment record along with customer and vehicle name
CREATE VIEW Payment_Record
AS
SELECT vehicle_name,customer_name,P.*
FROM payment AS P
JOIN vehicles AS V USING (vehicle_ID)
JOIN customer AS C ON P.customer_ID=C.customer_ID;

SELECT * FROM Payment_Record;

-- Creating view of the total amount of service done by each vehicle over all {Expense on each vehicle} 
CREATE VIEW Vehicle_Service_Expense
AS 
SELECT vehicle_ID, customer_ID, SUM(service_cost + material_cost) AS 'Total Cost'
FROM record
GROUP BY vehicle_ID, customer_ID;

SELECT * FROM Vehicle_Service_Expense;

-- Creating a view of total amount paid by each customer on a vehicel service over all {Bill Amount paid by each person}
CREATE VIEW Vehicle_Bill_Paid
AS
SELECT vehicle_ID, customer_ID, SUM(total_amount) AS 'Total Amount Paid'
FROM payment
GROUP BY vehicle_ID, customer_ID;

SELECT * FROM Vehicle_Bill_Paid;

-- Creating View of Salary Expenditure for each team 'Team_Salary_Split_Up'
CREATE VIEW Team_Salary_Split_Up
AS
SELECT E.team_ID, T.team_name, SUM(ann_salary)
FROM employee AS E
JOIN team AS T ON E.team_ID = T.team_ID
GROUP BY E.team_ID, T.team_name;

SELECT * FROM Team_Salary_Split_Up;

-- Creating View all the team managers and therir team name 
CREATE VIEW Board_of_Managers
AS
SELECT emp_ID,E.emp_name,D.team_ID,team_name 
FROM departments AS D
JOIN employee AS E ON E.emp_ID=D.mng_ID
JOIN team AS T ON T.team_ID=D.team_ID;

SELECT * FROM Board_of_Managers;

-- Creating view of Total Amount of service done by each team {Expense by the team}
CREATE VIEW Team_Expense
AS
SELECT DISTINCT team_ID,team_name,SUM(R.service_cost + R.material_cost) AS total_cost
FROM record AS R
JOIN payment USING (record_ID,vehicle_ID)
JOIN used AS U USING (record_ID)
JOIN team AS T USING (team_ID)
GROUP BY team_ID;

SELECT * FROM Team_Expense;

-- Creating View of Total Amount paid towards each teams work {Amount earned BY each team}
CREATE VIEW Team_Paid
AS
SELECT T.team_ID, T.team_name, SUM(total_amount) AS total_bill_amount
FROM payment AS P
JOIN record AS R USING (record_ID)
JOIN used AS U USING (record_ID)
JOIN team AS T USING(team_ID)
GROUP BY T.team_ID, T.team_name;

SELECT * FROM Team_paid;

-- Creating view of Profit margin of each team
CREATE VIEW Profit_Margin
AS
SELECT TP.team_ID,TP.team_name,TP.total_bill_amount - TE.total_cost AS Profit_Margin
FROM Team_Paid AS TP
JOIN Team_Expense AS TE ON TP.team_name=TE.team_name;

SELECT * FROM Profit_Margin;

-- Query Statements

-- Total worth of Stocks in the inventory
SELECT SUM(total_price)
FROM parts;

-- Getting Details of a perticular customer
SELECT * FROM customer WHERE customer_name Like'%Rao%';
 

-- Listing All employees of a particulat team
SELECT * FROM employee WHERE team_ID = 1; -- engine team team_ID =1

-- List Of vehicles ongoing service
SELECT * FROM vehicles
WHERE vehicle_ID IN (SELECT vehicle_ID FROM record WHERE delivery_date IS NULL);

-- List of payments Where payment is pending 
SELECT * FROM payment WHERE payment_status = 'PENDING';

-- List the employees directly under the manager 
SELECT * FROM employee WHERE mng_ID = 1;

-- List of vehicles purchsed in the year 2023
SELECT * FROM vehicles WHERE pur_year = 2023;

-- Total sales of the month of DECEMBER
SELECT SUM(total_amount) FROM payment WHERE MONTH(payment_date)=12;

-- List of vehicles serviced till today {overdue vehicles}
SELECT * FROM vehicles
WHERE vehicle_ID IN (SELECT vehicle_ID FROM record WHERE delivery_date < CURDATE());


-- Customer With High Payment ie payment above average payment
SELECT * FROM customer
WHERE customer_ID IN (SELECT customer_ID FROM payment WHERE total_amount > (SELECT AVG(total_amount) FROM payment));


-- List of vehicles and teams responsible
SELECT DISTINCT vehicle_name, team_name
FROM vehicles
JOIN used USING (vehicle_ID)
JOIN team USING (team_ID);

-- Average cost vehicle service on each vehicle
SELECT vehicle_ID, AVG(service_cost+material_cost) AS avg_service_cost
FROM record
GROUP BY vehicle_ID;

-- Average cost vehicle serviced	 
SELECT AVG(service_cost+material_cost) AS avg_service_cost
FROM record;

-- Average Bill amount paid by a customer
SELECT AVG(total_amount) FROM payment;

-- Average Profit Margin on a Vehicle
SELECT 
(SELECT AVG(total_amount) FROM payment)-
(SELECT AVG(service_cost+material_cost) AS avg_service_cost
FROM record) AS 'Average Profit Margin on a Vehicle';

-- List number of employees in each team
SELECT T.team_ID,team_name, COUNT(E.emp_ID) AS employee_count
FROM team AS T
LEFT JOIN employee AS E ON T.team_ID = E.team_ID
GROUP BY team_ID;

-- List of Customers having more than 1 two-wheelers  
SELECT customer_ID, COUNT(vehicle_ID) AS vehicle_count
FROM vehicles
GROUP BY customer_ID
HAVING COUNT(vehicle_ID) > 1;

-- List of vehicle not Serviced till date
SELECT * FROM vehicles
WHERE vehicle_ID NOT IN (SELECT DISTINCT vehicle_ID FROM record);

-- List of employees and their managers names
SELECT e.emp_ID, e.emp_name,e.mng_ID,m.emp_name AS manager_name
FROM employee e
LEFT JOIN employee m ON e.mng_ID = m.emp_ID;

-- Finding Total Amount of Service done
SELECT SUM(service_cost)+SUM(material_cost) 
FROM record;

-- Salary Expenditure bared by the company
SELECT SUM(ann_salary) AS total_salary_expenditure FROM employee;


