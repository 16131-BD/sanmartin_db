-- Listar a los alumnos con el curso en el que están matriculados
SELECT 
    c.name AS curso,
    p.names || ' ' || p.father_last_name || ' ' || p.mother_last_name AS alumno
FROM enrollment_details ed
JOIN enrollments e ON e.id = ed.enrollment_id
JOIN students s ON s.id = e.student_id
JOIN people p ON p.id = s.person_id
JOIN teachers_by_course tbc ON tbc.id = ed.course_assigned_id
JOIN courses c ON c.id = tbc.course_id
ORDER BY c.name, alumno;

-- Listar los cursos y cuántos alumnos tiene
SELECT 
    c.name AS curso,
    COUNT(s.id) AS cantidad_alumnos
FROM enrollment_details ed
JOIN enrollments e ON e.id = ed.enrollment_id
JOIN students s ON s.id = e.student_id
JOIN teachers_by_course tbc ON tbc.id = ed.course_assigned_id
JOIN courses c ON c.id = tbc.course_id
GROUP BY c.name
ORDER BY cantidad_alumnos DESC;

-- Listar alumnos por curso y el docente responsable
SELECT 
    c.name AS curso,
    p_student.names || ' ' || p_student.father_last_name AS alumno,
    p_teacher.names || ' ' || p_teacher.father_last_name AS docente
FROM enrollment_details ed
JOIN enrollments e ON e.id = ed.enrollment_id
JOIN students s ON s.id = e.student_id
JOIN people p_student ON p_student.id = s.person_id
JOIN teachers_by_course tbc ON tbc.id = ed.course_assigned_id
JOIN teachers t ON t.id = tbc.teacher_id
JOIN people p_teacher ON p_teacher.id = t.person_id
JOIN courses c ON c.id = tbc.course_id
ORDER BY c.name, alumno;

-- Buscar alumnos matriculados en un curso específico
SELECT 
    c.name AS curso,
    p.names || ' ' || p.father_last_name AS alumno
FROM enrollment_details ed
JOIN enrollments e ON e.id = ed.enrollment_id
JOIN students s ON s.id = e.student_id
JOIN people p ON p.id = s.person_id
JOIN teachers_by_course tbc ON tbc.id = ed.course_assigned_id
JOIN courses c ON c.id = tbc.course_id
WHERE c.name = 'Matemáticas'
ORDER BY alumno;
