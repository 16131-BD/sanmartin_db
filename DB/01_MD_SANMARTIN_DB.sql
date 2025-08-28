drop table if exists students;
drop table if exists courses;
drop table if exists teachers;
drop table if exists students_by_courses;
drop table if exists teachers_by_courses;
drop table if exists enrollments;
drop table if exists enrollment_details;

create table people(
	id serial primary key,
	dni varchar(8) not null unique,
	names varchar(500),
	father_last_name varchar(500),
	mother_last_name varchar(500),
	gender boolean default true,
	status boolean default true,
	created_at timestamp with time zone default current_date,
	updated_at timestamp with time zone
);

create table teachers(
	id serial primary key,
	person_id int references people(id),
	status boolean default true,
	created_at timestamp with time zone default current_date,
	updated_at timestamp with time zone
);
	
create table students(
	id serial primary key,
	person_id int references people(id),
	status varchar(2),
	birth_date date,
	created_at timestamp with time zone default current_date,
	updated_at timestamp with time zone
);

create table courses(
	id serial primary key,
	name varchar(500),
	description varchar(500),
	status boolean default true,
	created_at timestamp with time zone default current_date,
	updated_at timestamp with time zone
);

create table teachers_by_course(
	id serial primary key,
	teacher_id int references teachers(id),
	course_id int references courses(id),
	quantity_hours int,
	status boolean default true,
	created_at timestamp with time zone default current_date,
	updated_at timestamp with time zone
);

create table enrollments(
	id serial primary key,
	student_id int references students(id),
	amount numeric,
	disacount numeric,
	quantity_courses int,
	status boolean default true,
	created_at timestamp with time zone default current_date,
	updated_at timestamp with time zone
);

create table enrollment_details(
	id serial primary key,
	enrollment_id int references enrollments(id),
	course_assigned_id int references teachers_by_course(id),
    score numeric,
	status boolean default true,
	created_at timestamp with time zone default current_date,
	updated_at timestamp with time zone
);
