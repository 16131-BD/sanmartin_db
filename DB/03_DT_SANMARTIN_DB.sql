INSERT INTO people (dni, names, father_last_name, mother_last_name, gender)
VALUES 
('12345678', 'Juan', 'Pérez', 'Gómez', true),
('23456789', 'María', 'Rodríguez', 'Díaz', false),
('34567890', 'Carlos', 'López', 'Fernández', true),
('45678901', 'Lucía', 'Ramírez', 'Torres', false),
('56789012', 'Ana', 'Martínez', 'Ruiz', false),
('67890123', 'Pedro', 'Sánchez', 'Vega', true);

INSERT INTO teachers (person_id)
VALUES 
(1),  -- Juan Pérez
(2);  -- María Rodríguez

INSERT INTO students (person_id, status, birth_date)
VALUES 
(3, 'A', '2005-03-15'),  -- Carlos López
(4, 'A', '2004-07-21'),  -- Lucía Ramírez
(5, 'A', '2006-01-10'),  -- Ana Martínez
(6, 'A', '2003-11-05');  -- Pedro Sánchez


INSERT INTO courses (name, description)
VALUES 
('Matemáticas', 'Curso básico de matemáticas'),
('Lenguaje', 'Curso de gramática y literatura'),
('Ciencias', 'Curso de ciencias naturales');

INSERT INTO teachers_by_course (teacher_id, course_id, quantity_hours)
VALUES 
(1, 1, 40),  -- Juan - Matemáticas
(1, 2, 30),  -- Juan - Lenguaje
(2, 3, 35);  -- María - Ciencias


INSERT INTO enrollments (student_id, amount, disacount, quantity_courses)
VALUES 
(1, 300.00, 0, 2),  -- Carlos
(2, 450.00, 50, 3), -- Lucía
(3, 150.00, 0, 1),  -- Ana
(4, 300.00, 0, 2);  -- Pedro

-- Carlos: Matemáticas y Lenguaje
INSERT INTO enrollment_details (enrollment_id, course_assigned_id)
VALUES 
(1, 1), 
(1, 2);

-- Lucía: Matemáticas, Lenguaje y Ciencias
INSERT INTO enrollment_details (enrollment_id, course_assigned_id)
VALUES 
(2, 1),
(2, 2),
(2, 3);

-- Ana: Ciencias
INSERT INTO enrollment_details (enrollment_id, course_assigned_id)
VALUES 
(3, 3);

-- Pedro: Matemáticas y Ciencias
INSERT INTO enrollment_details (enrollment_id, course_assigned_id)
VALUES 
(4, 1),
(4, 3);

-- ALTER TABLE enrollment_details add constraint check_score check (score <= 20);
