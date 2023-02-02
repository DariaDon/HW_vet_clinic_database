CREATE TABLE PATIENT
(
    animal_ID serial NOT NULL PRIMARY KEY,
	name varchar NOT NULL,
    date_of_birth date,
	gender varchar(1),
	species varchar,
	breed varchar
);

CREATE TABLE OWNER
(
	owner_ID serial NOT NULL PRIMARY KEY,
	name varchar NOT NULL,
	phone_number numeric(11,0),
	passport_series integer NOT NULL,
	passport_number varchar(6) NOT NULL
);
CREATE INDEX OWNER_passport_IDX ON OWNER (passport_series, passport_number);

CREATE TABLE RELATION_OWNER_PATIENT
(
	animal_ID integer REFERENCES PATIENT (animal_ID),
	owner_ID integer REFERENCES OWNER (owner_ID),
	PRIMARY KEY (animal_ID, owner_ID)
);
CREATE INDEX RELATION_OWNER_PATIENT_OWNER_ID_IDX ON RELATION_OWNER_PATIENT (owner_ID);

CREATE TABLE DOCTOR
(
    doctor_ID serial NOT NULL PRIMARY KEY,
	name varchar NOT NULL,
	specialization varchar
);

CREATE TABLE SCHEDULE
(
	doctor_ID integer REFERENCES DOCTOR (doctor_ID),
	working_days date NOT NULL,
	start_time time NOT NULL,
	end_time time NOT NULL
);
CREATE INDEX SCHEDULE_working_days_IDX ON SCHEDULE (working_days);

CREATE TABLE APPOINTMENT
(
	appointment_ID serial NOT NULL PRIMARY KEY,
    animal_ID integer REFERENCES PATIENT (animal_ID),
	owner_ID integer REFERENCES OWNER (owner_ID),
	doctor_ID integer REFERENCES DOCTOR (doctor_ID),
	datetime_of_appointment timestamp,
	diagnosis varchar,
	treatment varchar,
	receipt_number integer
);
CREATE INDEX APPOINTMENT_animal_ID_idx ON APPOINTMENT (animal_ID, datetime_of_appointment);
CREATE INDEX APPOINTMENT_owner_ID_idx ON APPOINTMENT (owner_ID, datetime_of_appointment);
CREATE INDEX APPOINTMENT_doctor_ID_idx ON APPOINTMENT (doctor_ID, datetime_of_appointment);
CREATE INDEX APPOINTMENT_datetime_of_appointment_idx ON APPOINTMENT (datetime_of_appointment);

CREATE TABLE SERVICE
(
	service_ID serial NOT NULL PRIMARY KEY,
	name varchar NOT NULL,
	cost money
);

CREATE TABLE RELATION_SERVICE_APPOINTMENT
(
	appointment_ID integer REFERENCES APPOINTMENT (appointment_ID),
	service_ID integer REFERENCES SERVICE (service_ID),
	number_of_services integer,
	cost money,
	primary key (appointment_ID, service_ID)
);
CREATE INDEX RELATION_SERVICE_APPOINTMENT_service_ID_idx ON RELATION_SERVICE_APPOINTMENT (service_ID);

SET lc_monetary TO "ru_RU.UTF-8";

INSERT INTO SERVICE (name, cost) VALUES
    ('Вакцинация от бешенства', 400),
    ('Чипирование', 1200),
    ('Измерение артериального давления животным', 300),
	('УЗИ брюшной полости', 1200),
	('УЗИ головного мозга', 700),
	('УЗИ сердца', 1700),
	('ЭКГ', 1200),
	('Общий анализ крови', 500),
	('Биохимический анализ крови', 1200),
	('Прием ветеринара', 800),
	('Стерилизация', 3000);
	
INSERT INTO DOCTOR (name, specialization) VALUES
	('Кузьмин Илья Петрович', 'Терапевт'),
	('Голубев Тарас Адольфович', 'Невропатолог'),
	('Борисова Алина Константиновна', 'Хирург');
	
INSERT INTO SCHEDULE (doctor_ID, working_days, start_time, end_time) VALUES
	(1, '2023-01-01', '09:00:00', '21:00:00'),
	(1, '2023-01-02', '09:00:00', '21:00:00'),
	(2, '2023-01-03', '09:00:00', '21:00:00'),
	(2, '2023-01-04', '09:00:00', '21:00:00'),
	(3, '2023-01-05', '09:00:00', '21:00:00'),
	(3, '2023-01-06', '09:00:00', '21:00:00');
	
CREATE OR REPLACE PROCEDURE ADD_OWNER_AND_PATIENT
(
	name_owner varchar,
	phone_number_owner numeric,
	passport_series_owner integer,
	passport_number_owner varchar(6),
	name_patient varchar,
	date_of_birth_patient date,
	gender_patient varchar(1),
	species_patient varchar,
	breed_patient varchar
)
LANGUAGE plpgsql AS
$$
BEGIN
	IF NOT EXISTS(SELECT passport_series, passport_number FROM OWNER
				  WHERE passport_series=passport_series_owner AND passport_number=passport_number_owner) THEN
		INSERT INTO OWNER (name, phone_number, passport_series, passport_number) VALUES
		(name_owner, phone_number_owner, passport_series_owner, passport_number_owner);

		INSERT INTO PATIENT (name, date_of_birth, gender, species, breed) VALUES
		(name_patient, date_of_birth_patient, gender_patient, species_patient, breed_patient);
	
		INSERT INTO RELATION_OWNER_PATIENT(animal_ID, owner_ID) VALUES
		(currval('patient_animal_id_seq'), currval('owner_owner_id_seq'));
	ELSE
    	RAISE NOTICE 'Клиент с таким паспортом уже внесен';
  	END IF;
END
$$;

CALL ADD_OWNER_AND_PATIENT('Веселов Юлиан Вадимович', 79226955813, 8976, '123450', 'Сумрак', '2019-09-12', 'м', 'хомяк', 'джунгарский');
CALL ADD_OWNER_AND_PATIENT('Макаров Ефим Иосифович', 79961220779, 9056, '643759', 'Ралли', '2008-08-28', 'ж', 'собака', 'далматинец');

CREATE OR REPLACE PROCEDURE ADD_PATIENT
(
	owner_ID integer,
	name_patient varchar,
	date_of_birth_patient date,
	gender_patient varchar(1),
	species_patient varchar,
	breed_patient varchar
)
LANGUAGE plpgsql AS
$$
BEGIN

	INSERT INTO PATIENT (name, date_of_birth, gender, species, breed) VALUES
	(name_patient, date_of_birth_patient, gender_patient, species_patient, breed_patient);
	
	INSERT INTO RELATION_OWNER_PATIENT(animal_ID, owner_ID) VALUES
	(currval('patient_animal_id_seq'), owner_ID);
END
$$;

CALL ADD_PATIENT(1, 'Бренди', '2006-09-02', 'ж', 'кот', 'неизвестна');


CREATE OR REPLACE PROCEDURE ADD_OWNER
(
	name_owner varchar,
	phone_number_owner numeric,
	passport_series_owner integer,
	passport_number_owner varchar(6),
	animal_ID integer
)
LANGUAGE plpgsql AS
$$
BEGIN
	IF NOT EXISTS(SELECT passport_series, passport_number FROM OWNER
				  WHERE passport_series=passport_series_owner AND passport_number=passport_number_owner) THEN
		INSERT INTO OWNER (name, phone_number, passport_series, passport_number) VALUES
		(name_owner, phone_number_owner, passport_series_owner, passport_number_owner);
	
		INSERT INTO RELATION_OWNER_PATIENT(animal_ID, owner_ID) VALUES
		(animal_ID, currval('owner_owner_id_seq'));
	ELSE
    	RAISE NOTICE 'Клиент с таким паспортом уже внесен';
  	END IF;
END
$$;

CALL ADD_OWNER('Ковалёв Андрей Федотович', 79960641532, 5687, '098765', 2);

INSERT INTO APPOINTMENT (animal_ID, owner_ID, doctor_ID, datetime_of_appointment, diagnosis, treatment, receipt_number) VALUES
	(1, 1, 1, '2023-01-10 12:00:00', 'рана на лапке', 'промывать чем-то', 1);
	
CREATE OR REPLACE FUNCTION ADD_IN_RELATION_SERVICE_APPOINTMENT() RETURNS TRIGGER
LANGUAGE plpgsql AS
$$
BEGIN
	IF TG_OP='UPDATE' AND OLD.service_ID=NEW.service_ID THEN
		RETURN NEW;
	END IF;
	NEW.cost=(SELECT cost FROM SERVICE WHERE service_ID=NEW.service_ID);
	RETURN NEW;
END
$$;

CREATE TRIGGER ADD_IN_RELATION_SERVICE_APPOINTMENT
BEFORE INSERT OR UPDATE ON RELATION_SERVICE_APPOINTMENT
FOR EACH ROW EXECUTE PROCEDURE ADD_IN_RELATION_SERVICE_APPOINTMENT();

INSERT INTO RELATION_SERVICE_APPOINTMENT(appointment_ID, service_ID, number_of_services) VALUES
	(1, 2, 2);

CREATE VIEW APPOINTMENT_FULL
AS SELECT a.*, o.name as owner_name, o.phone_number as owner_phone_number, p.name as patient_, p.date_of_birth as patient_date_of_birth,
p.gender as patient_gender, p.species as patient_species, p.breed as patient_breed, d.name as doctor_name,
d.specialization as doctor_specialization,
(SELECT SUM(number_of_services*cost) FROM RELATION_SERVICE_APPOINTMENT WHERE appointment_ID=a.appointment_ID)
FROM APPOINTMENT a
JOIN OWNER o ON (o.owner_ID=a.owner_ID)
JOIN PATIENT p ON (p.animal_ID=a.animal_ID)
JOIN DOCTOR d ON (d.doctor_ID=a.doctor_ID);

CREATE VIEW SERVICE_APPOINTMENT
AS SELECT r.*, s.name as service_name
FROM RELATION_SERVICE_APPOINTMENT r
JOIN SERVICE s ON (s.service_ID=r.service_ID);

CREATE VIEW SCHEDULE_DOCTOR
AS SELECT s.*, d.name as doctor_name, d.specialization as doctor_specialization
FROM SCHEDULE as s
JOIN DOCTOR as d ON (d.doctor_ID=s.doctor_ID);

CREATE ROLE ADMIN;
GRANT CONNECT ON DATABASE "HW" TO ADMIN;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA PUBLIC TO ADMIN;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA PUBLIC TO ADMIN;
GRANT ALL PRIVILEGES ON ALL PROCEDURES IN SCHEMA PUBLIC TO ADMIN;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA PUBLIC TO ADMIN;

CREATE ROLE DOCTOR;
GRANT CONNECT ON DATABASE "HW" TO DOCTOR;
GRANT ALL PRIVILEGES ON TABLE APPOINTMENT TO DOCTOR;
GRANT ALL PRIVILEGES ON TABLE RELATION_SERVICE_APPOINTMENT TO DOCTOR;
GRANT ALL PRIVILEGES ON SEQUENCE appointment_appointment_id_seq TO DOCTOR;
GRANT SELECT ON ALL TABLES IN SCHEMA PUBLIC TO DOCTOR;

CREATE ROLE RECEPTIONIST;
GRANT CONNECT ON DATABASE "HW" TO RECEPTIONIST;
GRANT ALL PRIVILEGES ON TABLE PATIENT TO RECEPTIONIST;
GRANT ALL PRIVILEGES ON TABLE OWNER TO RECEPTIONIST;
GRANT ALL PRIVILEGES ON TABLE RELATION_OWNER_PATIENT TO RECEPTIONIST;
GRANT ALL PRIVILEGES ON SEQUENCE patient_animal_id_seq TO DOCTOR;
GRANT ALL PRIVILEGES ON SEQUENCE owner_owner_id_seq TO DOCTOR;
GRANT SELECT ON ALL TABLES IN SCHEMA PUBLIC TO RECEPTIONIST;