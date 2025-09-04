
/***************************************************************************************************
 * PEOPLE
 ***************************************************************************************************/
DROP FUNCTION IF EXISTS public.fx_sel_people(JSONB);
CREATE FUNCTION public.fx_sel_people(JSONB)
RETURNS TABLE (
    id INT,
    dni VARCHAR,
    names VARCHAR,
    father_last_name VARCHAR,
    mother_last_name VARCHAR,
    gender BOOLEAN,
    status BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
)
AS $$
DECLARE
    p_json_data ALIAS FOR $1;
BEGIN
    RETURN QUERY
    WITH filtros AS (
        SELECT
            x.id,
            x.dni,
            x.names,
            x.father_last_name,
            x.mother_last_name,
            x.gender,
            x.status,
            x.created_at
        FROM JSONB_TO_RECORDSET(COALESCE(p_json_data,'[]'::JSONB)) AS x(
            id INT,
            dni VARCHAR(8),
            names VARCHAR(500),
            father_last_name VARCHAR(500),
            mother_last_name VARCHAR(500),
            gender BOOLEAN,
            status BOOLEAN,
            created_at TIMESTAMP WITH TIME ZONE
        )
    )
    SELECT
        p.id,
        p.dni,
        p.names,
        p.father_last_name,
        p.mother_last_name,
        p.gender,
        p.status,
        p.created_at,
        p.updated_at
    FROM people p
    LEFT JOIN filtros f ON TRUE
    WHERE (f.id IS NULL OR p.id = f.id)
      AND (f.dni IS NULL OR p.dni ILIKE '%' || f.dni || '%')
      AND (f.names IS NULL OR p.names ILIKE '%' || f.names || '%')
      AND (f.father_last_name IS NULL OR p.father_last_name ILIKE '%' || f.father_last_name || '%')
      AND (f.mother_last_name IS NULL OR p.mother_last_name ILIKE '%' || f.mother_last_name || '%')
      AND (f.gender IS NULL OR p.gender = f.gender)
      AND (f.status IS NULL OR p.status = f.status)
      AND (f.created_at IS NULL OR DATE(p.created_at) = DATE(f.created_at));
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER COST 1000;

COMMENT ON FUNCTION public.fx_sel_people(JSONB) IS
$$
OBJETIVO : Consultar registros en people con filtros opcionales enviados en JSONB
SINTAXIS DE EJEMPLO:
-- Todos los registros
SELECT * FROM public.fx_sel_people(NULL);

-- Filtrar por DNI
SELECT * FROM public.fx_sel_people('[{"dni":"12345678"}]'::jsonb);
$$;


DROP FUNCTION IF EXISTS public.fx_ins_people(JSONB);
CREATE FUNCTION public.fx_ins_people(JSONB)
RETURNS TABLE (
    id INT,
    dni VARCHAR
)
AS $$
DECLARE
    p_json_data ALIAS FOR $1;
BEGIN
    DROP TABLE IF EXISTS tmp_people;
    CREATE TEMPORARY TABLE tmp_people AS
    SELECT
        x.dni,
        x.names,
        x.father_last_name,
        x.mother_last_name,
        x.gender,
        x.status,
        x.created_at,
        x.updated_at
    FROM JSONB_TO_RECORDSET(COALESCE(p_json_data,'[]'::JSONB)) AS x(
        dni VARCHAR(8),
        names VARCHAR(500),
        father_last_name VARCHAR(500),
        mother_last_name VARCHAR(500),
        gender BOOLEAN,
        status BOOLEAN,
        created_at TIMESTAMP WITH TIME ZONE,
        updated_at TIMESTAMP WITH TIME ZONE
    );

    RETURN QUERY
    INSERT INTO people(
        dni,
        names,
        father_last_name,
        mother_last_name,
        gender,
        status,
        created_at,
        updated_at
    )
    SELECT
        TRIM(B.dni),
        INITCAP(TRIM(B.names)),
        INITCAP(TRIM(B.father_last_name)),
        INITCAP(TRIM(B.mother_last_name)),
        COALESCE(B.gender, TRUE),
        COALESCE(B.status, TRUE),
        COALESCE(B.created_at, CURRENT_TIMESTAMP),
        B.updated_at
    FROM tmp_people B
    RETURNING id, dni;
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER COST 1000;

COMMENT ON FUNCTION public.fx_ins_people(JSONB) IS
$$
OBJETIVO : Insertar registros en people desde JSONB
SINTAXIS:
SELECT * FROM public.fx_ins_people(
  '[{"dni":"12345678","names":"Juan Perez","father_last_name":"Perez","mother_last_name":"Lopez","gender":true,"created_at":"2025-01-01T10:00:00Z","status":true}]'::jsonb
);
$$;


DROP FUNCTION IF EXISTS public.fx_upd_people(JSONB);
CREATE FUNCTION public.fx_upd_people(JSONB)
RETURNS BOOLEAN
AS $$
DECLARE
    p_json_data ALIAS FOR $1;
BEGIN
    DROP TABLE IF EXISTS tmp_people_upd;
    CREATE TEMPORARY TABLE tmp_people_upd AS
    SELECT
        x.id,
        x.dni,
        x.names,
        x.father_last_name,
        x.mother_last_name,
        x.gender,
        x.status,
        x.updated_at
    FROM JSONB_TO_RECORDSET(COALESCE(p_json_data,'[]'::JSONB)) AS x(
        id INT,
        dni VARCHAR(8),
        names VARCHAR(500),
        father_last_name VARCHAR(500),
        mother_last_name VARCHAR(500),
        gender BOOLEAN,
        status BOOLEAN,
        updated_at TIMESTAMP WITH TIME ZONE
    );

    UPDATE people p
    SET
        dni = COALESCE(TRIM(u.dni), p.dni),
        names = COALESCE(INITCAP(TRIM(u.names)), p.names),
        father_last_name = COALESCE(INITCAP(TRIM(u.father_last_name)), p.father_last_name),
        mother_last_name = COALESCE(INITCAP(TRIM(u.mother_last_name)), p.mother_last_name),
        gender = COALESCE(u.gender, p.gender),
        status = COALESCE(u.status, p.status),
        updated_at = COALESCE(u.updated_at, CURRENT_TIMESTAMP)
    FROM tmp_people_upd u
    WHERE p.id = u.id;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER COST 1000;

COMMENT ON FUNCTION public.fx_upd_people(JSONB) IS
$$
OBJETIVO : Actualizar registros en people (actualización parcial mediante JSONB)
SINTAXIS:
SELECT public.fx_upd_people('[{"id":1,"names":"Juanito Perez","updated_at":"2025-08-01T12:00:00Z"}]'::jsonb);
$$;


-- ******************************************************************
-- TEACHERS
-- ******************************************************************
DROP FUNCTION IF EXISTS public.fx_sel_teachers(JSONB);
CREATE FUNCTION public.fx_sel_teachers(JSONB)
RETURNS TABLE (
    id INT,
    person_id INT,
    dni VARCHAR,
    names VARCHAR,
    father_last_name VARCHAR,
    mother_last_name VARCHAR,
    status BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
)
AS $$
DECLARE
    p_json_data ALIAS FOR $1;
BEGIN
    RETURN QUERY
    WITH filtros AS (
      SELECT
        x.id,
        x.person_id,
        x.status,
        x.created_at
      FROM JSONB_TO_RECORDSET(COALESCE(p_json_data,'[]'::JSONB)) AS x(
        id INT,
        person_id INT,
        status BOOLEAN,
        created_at TIMESTAMP WITH TIME ZONE
      )
    )
    SELECT
      t.id,
      t.person_id,
      p.dni,
      p.names,
      p.father_last_name,
      p.mother_last_name,
      t.status,
      t.created_at,
      t.updated_at
    FROM teachers t
    LEFT JOIN people p ON p.id = t.person_id
    LEFT JOIN filtros f ON TRUE
    WHERE (f.id IS NULL OR t.id = f.id)
      AND (f.person_id IS NULL OR t.person_id = f.person_id)
      AND (f.status IS NULL OR t.status = f.status)
      AND (f.created_at IS NULL OR DATE(t.created_at) = DATE(f.created_at));
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER COST 1000;

COMMENT ON FUNCTION public.fx_sel_teachers(JSONB) IS
$$
OBJETIVO : Consultar teachers (posible join con people)
SINTAXIS:
SELECT * FROM public.fx_sel_teachers(NULL);
SELECT * FROM public.fx_sel_teachers('[{"person_id":2}]'::jsonb);
$$;


DROP FUNCTION IF EXISTS public.fx_ins_teachers(JSONB);
CREATE FUNCTION public.fx_ins_teachers(JSONB)
RETURNS BOOLEAN
AS $$
DECLARE
    p_json_data ALIAS FOR $1;
BEGIN
    DROP TABLE IF EXISTS tmp_teachers;
    CREATE TEMPORARY TABLE tmp_teachers AS
    SELECT
        x.person_id,
        x.status,
        x.created_at,
        x.updated_at
    FROM JSONB_TO_RECORDSET(COALESCE(p_json_data,'[]'::JSONB)) AS x(
        person_id INT,
        status BOOLEAN,
        created_at TIMESTAMP WITH TIME ZONE,
        updated_at TIMESTAMP WITH TIME ZONE
    );

    INSERT INTO teachers(
        person_id,
        status,
        created_at,
        updated_at
    )
    SELECT
        person_id,
        COALESCE(status, TRUE),
        COALESCE(created_at, CURRENT_TIMESTAMP),
        updated_at
    FROM tmp_teachers;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER COST 1000;

COMMENT ON FUNCTION public.fx_ins_teachers(JSONB) IS
$$
OBJETIVO : Insertar registros en teachers
SINTAXIS:
SELECT public.fx_ins_teachers('[{"person_id":1,"status":true}]'::jsonb);
$$;


DROP FUNCTION IF EXISTS public.fx_upd_teachers(JSONB);
CREATE FUNCTION public.fx_upd_teachers(JSONB)
RETURNS BOOLEAN
AS $$
DECLARE
    p_json_data ALIAS FOR $1;
BEGIN
    DROP TABLE IF EXISTS tmp_teachers_upd;
    CREATE TEMPORARY TABLE tmp_teachers_upd AS
    SELECT
        x.id,
        x.person_id,
        x.status,
        x.updated_at
    FROM JSONB_TO_RECORDSET(COALESCE(p_json_data,'[]'::JSONB)) AS x(
        id INT,
        person_id INT,
        status BOOLEAN,
        updated_at TIMESTAMP WITH TIME ZONE
    );

    UPDATE teachers t
    SET
        person_id = COALESCE(u.person_id, t.person_id),
        status = COALESCE(u.status, t.status),
        updated_at = COALESCE(u.updated_at, CURRENT_TIMESTAMP)
    FROM tmp_teachers_upd u
    WHERE t.id = u.id;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER COST 1000;

COMMENT ON FUNCTION public.fx_upd_teachers(JSONB) IS
$$
OBJETIVO : Actualizar registros en teachers (parcial)
SINTAXIS:
SELECT public.fx_upd_teachers('[{"id":1,"status":false}]'::jsonb);
$$;


-- ******************************************************************
-- STUDENTS
-- ******************************************************************
DROP FUNCTION IF EXISTS public.fx_sel_students(JSONB);
CREATE FUNCTION public.fx_sel_students(JSONB)
RETURNS TABLE (
    id INT,
    person_id INT,
    dni VARCHAR,
    names VARCHAR,
    father_last_name VARCHAR,
    mother_last_name VARCHAR,
    status VARCHAR,
    birth_date DATE,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
)
AS $$
DECLARE
    p_json_data ALIAS FOR $1;
    v_person_id INT;
    v_status TEXT;
BEGIN
    -- Permitir filtro por person_id y status (texto) si se quiere
    SELECT x.person_id, x.status INTO v_person_id, v_status
    FROM JSONB_TO_RECORD(COALESCE(p_json_data,'{}'::JSONB)) AS x(person_id INT, status VARCHAR);

    RETURN QUERY
    SELECT
        s.id,
        s.person_id,
        p.dni,
        p.names,
        p.father_last_name,
        p.mother_last_name,
        s.status,
        s.birth_date,
        s.created_at,
        s.updated_at
    FROM students s
    INNER JOIN people p ON p.id = s.person_id
    WHERE (v_person_id IS NULL OR s.person_id = v_person_id)
      AND (v_status IS NULL OR s.status = v_status);
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER COST 1000;

COMMENT ON FUNCTION public.fx_sel_students(JSONB) IS
$$
OBJETIVO : Consultar students con join a people
SINTAXIS:
SELECT * FROM public.fx_sel_students(NULL);
SELECT * FROM public.fx_sel_students('{"person_id":1}'::jsonb);
$$;


DROP FUNCTION IF EXISTS public.fx_ins_students(JSONB);
CREATE FUNCTION public.fx_ins_students(JSONB)
RETURNS BOOLEAN
AS $$
DECLARE
    p_json_data ALIAS FOR $1;
BEGIN
    DROP TABLE IF EXISTS tmp_students;
    CREATE TEMPORARY TABLE tmp_students AS
    SELECT
        x.person_id,
        x.status,
        x.birth_date,
        x.created_at,
        x.updated_at
    FROM JSONB_TO_RECORDSET(COALESCE(p_json_data,'[]'::JSONB)) AS x(
        person_id INT,
        status VARCHAR(2),
        birth_date DATE,
        created_at TIMESTAMP WITH TIME ZONE,
        updated_at TIMESTAMP WITH TIME ZONE
    );

    INSERT INTO students(
        person_id,
        status,
        birth_date,
        created_at,
        updated_at
    )
    SELECT
        person_id,
        status,
        birth_date,
        COALESCE(created_at, CURRENT_TIMESTAMP),
        updated_at
    FROM tmp_students;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER COST 1000;

COMMENT ON FUNCTION public.fx_ins_students(JSONB) IS
$$
OBJETIVO : Insertar registros en students
SINTAXIS:
SELECT public.fx_ins_students('[{"person_id":2,"status":"AC","birth_date":"2010-05-20","created_at":"2025-01-01T10:00:00Z"}]'::jsonb);
$$;


DROP FUNCTION IF EXISTS public.fx_upd_students(JSONB);
CREATE FUNCTION public.fx_upd_students(JSONB)
RETURNS BOOLEAN
AS $$
DECLARE
    p_json_data ALIAS FOR $1;
BEGIN
    DROP TABLE IF EXISTS tmp_students_upd;
    CREATE TEMPORARY TABLE tmp_students_upd AS
    SELECT
        x.id,
        x.person_id,
        x.status,
        x.birth_date,
        x.updated_at
    FROM JSONB_TO_RECORDSET(COALESCE(p_json_data,'[]'::JSONB)) AS x(
        id INT,
        person_id INT,
        status VARCHAR(2),
        birth_date DATE,
        updated_at TIMESTAMP WITH TIME ZONE
    );

    UPDATE students s
    SET
        person_id = COALESCE(u.person_id, s.person_id),
        status = COALESCE(u.status, s.status),
        birth_date = COALESCE(u.birth_date, s.birth_date),
        updated_at = COALESCE(u.updated_at, CURRENT_TIMESTAMP)
    FROM tmp_students_upd u
    WHERE s.id = u.id;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER COST 1000;

COMMENT ON FUNCTION public.fx_upd_students(JSONB) IS
$$
OBJETIVO : Actualizar students (parcial)
SINTAXIS:
SELECT public.fx_upd_students('[{"id":1,"status":"IN","updated_at":"2025-08-01T12:00:00Z"}]'::jsonb);
$$;


-- ******************************************************************
-- COURSES
-- ******************************************************************
DROP FUNCTION IF EXISTS public.fx_sel_courses(JSONB);
CREATE FUNCTION public.fx_sel_courses(JSONB)
RETURNS TABLE (
    id INT,
    name VARCHAR,
    description VARCHAR,
    status BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
)
AS $$
DECLARE
    p_json_data ALIAS FOR $1;
BEGIN
    RETURN QUERY
    WITH filtros AS (
      SELECT
        x.id,
        x.name,
        x.status,
        x.created_at
      FROM JSONB_TO_RECORDSET(COALESCE(p_json_data,'[]'::JSONB)) AS x(
        id INT,
        name VARCHAR(500),
        status BOOLEAN,
        created_at TIMESTAMP WITH TIME ZONE
      )
    )
    SELECT
      c.id,
      c.name,
      c.description,
      c.status,
      c.created_at,
      c.updated_at
    FROM courses c
    LEFT JOIN filtros f ON TRUE
    WHERE (f.id IS NULL OR c.id = f.id)
      AND (f.name IS NULL OR c.name ILIKE '%' || f.name || '%')
      AND (f.status IS NULL OR c.status = f.status)
      AND (f.created_at IS NULL OR DATE(c.created_at) = DATE(f.created_at));
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER COST 1000;

COMMENT ON FUNCTION public.fx_sel_courses(JSONB) IS
$$
OBJETIVO : Consultar courses con filtros JSONB
SINTAXIS:
SELECT * FROM public.fx_sel_courses(NULL);
SELECT * FROM public.fx_sel_courses('[{"name":"Matematica"}]'::jsonb);
$$;


DROP FUNCTION IF EXISTS public.fx_ins_courses(JSONB);
CREATE FUNCTION public.fx_ins_courses(JSONB)
RETURNS BOOLEAN
AS $$
DECLARE
    p_json_data ALIAS FOR $1;
BEGIN
    DROP TABLE IF EXISTS tmp_courses;
    CREATE TEMPORARY TABLE tmp_courses AS
    SELECT
        x.name,
        x.description,
        x.status,
        x.created_at,
        x.updated_at
    FROM JSONB_TO_RECORDSET(COALESCE(p_json_data,'[]'::JSONB)) AS x(
        name VARCHAR(500),
        description VARCHAR(500),
        status BOOLEAN,
        created_at TIMESTAMP WITH TIME ZONE,
        updated_at TIMESTAMP WITH TIME ZONE
    );

    INSERT INTO courses(
        name,
        description,
        status,
        created_at,
        updated_at
    )
    SELECT
        INITCAP(TRIM(name)),
        description,
        COALESCE(status, TRUE),
        COALESCE(created_at, CURRENT_TIMESTAMP),
        updated_at
    FROM tmp_courses;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER COST 1000;

COMMENT ON FUNCTION public.fx_ins_courses(JSONB) IS
$$
OBJETIVO : Insertar registros en courses
SINTAXIS:
SELECT public.fx_ins_courses('[{"name":"Matemáticas","description":"Basica","status":true}]'::jsonb);
$$;


DROP FUNCTION IF EXISTS public.fx_upd_courses(JSONB);
CREATE FUNCTION public.fx_upd_courses(JSONB)
RETURNS BOOLEAN
AS $$
DECLARE
    p_json_data ALIAS FOR $1;
BEGIN
    DROP TABLE IF EXISTS tmp_courses_upd;
    CREATE TEMPORARY TABLE tmp_courses_upd AS
    SELECT
        x.id,
        x.name,
        x.description,
        x.status,
        x.updated_at
    FROM JSONB_TO_RECORDSET(COALESCE(p_json_data,'[]'::JSONB)) AS x(
        id INT,
        name VARCHAR(500),
        description VARCHAR(500),
        status BOOLEAN,
        updated_at TIMESTAMP WITH TIME ZONE
    );

    UPDATE courses c
    SET
        name = COALESCE(INITCAP(TRIM(u.name)), c.name),
        description = COALESCE(u.description, c.description),
        status = COALESCE(u.status, c.status),
        updated_at = COALESCE(u.updated_at, CURRENT_TIMESTAMP)
    FROM tmp_courses_upd u
    WHERE c.id = u.id;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER COST 1000;

COMMENT ON FUNCTION public.fx_upd_courses(JSONB) IS
$$
OBJETIVO : Actualizar courses (parcial)
SINTAXIS:
SELECT public.fx_upd_courses('[{"id":1,"name":"Matematicas Avanzadas"}]'::jsonb);
$$;


-- ******************************************************************
-- TEACHERS_BY_COURSE
-- ******************************************************************
DROP FUNCTION IF EXISTS public.fx_sel_teachers_by_course(JSONB);
CREATE FUNCTION public.fx_sel_teachers_by_course(JSONB)
RETURNS TABLE (
    id INT,
    teacher_id INT,
    teacher_person_id INT,
    teacher_dni VARCHAR,
    teacher_names VARCHAR,
    course_id INT,
    course_name VARCHAR,
    quantity_hours INT,
    status BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
)
AS $$
DECLARE
    p_json_data ALIAS FOR $1;
BEGIN
    RETURN QUERY
    WITH filtros AS (
      SELECT
        x.id,
        x.teacher_id,
        x.course_id,
        x.status,
        x.created_at
      FROM JSONB_TO_RECORDSET(COALESCE(p_json_data,'[]'::JSONB)) AS x(
        id INT,
        teacher_id INT,
        course_id INT,
        status BOOLEAN,
        created_at TIMESTAMP WITH TIME ZONE
      )
    )
    SELECT
      tbc.id,
      tbc.teacher_id,
      te.person_id as teacher_person_id,
      p.dni as teacher_dni,
      p.names as teacher_names,
      tbc.course_id,
      c.name as course_name,
      tbc.quantity_hours,
      tbc.status,
      tbc.created_at,
      tbc.updated_at
    FROM teachers_by_course tbc
    LEFT JOIN teachers te ON te.id = tbc.teacher_id
    LEFT JOIN people p ON p.id = te.person_id
    LEFT JOIN courses c ON c.id = tbc.course_id
    LEFT JOIN filtros f ON TRUE
    WHERE (f.id IS NULL OR tbc.id = f.id)
      AND (f.teacher_id IS NULL OR tbc.teacher_id = f.teacher_id)
      AND (f.course_id IS NULL OR tbc.course_id = f.course_id)
      AND (f.status IS NULL OR tbc.status = f.status)
      AND (f.created_at IS NULL OR DATE(tbc.created_at) = DATE(f.created_at));
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER COST 1000;

COMMENT ON FUNCTION public.fx_sel_teachers_by_course(JSONB) IS
$$
OBJETIVO : Consultar teachers_by_course con joins a teachers->people y courses
SINTAXIS:
SELECT * FROM public.fx_sel_teachers_by_course(NULL);
SELECT * FROM public.fx_sel_teachers_by_course('[{"teacher_id":1}]'::jsonb);
$$;


DROP FUNCTION IF EXISTS public.fx_ins_teachers_by_course(JSONB);
CREATE FUNCTION public.fx_ins_teachers_by_course(JSONB)
RETURNS BOOLEAN
AS $$
DECLARE
    p_json_data ALIAS FOR $1;
BEGIN
    DROP TABLE IF EXISTS tmp_teachers_by_course;
    CREATE TEMPORARY TABLE tmp_teachers_by_course AS
    SELECT
        x.teacher_id,
        x.course_id,
        x.quantity_hours,
        x.status,
        x.created_at,
        x.updated_at
    FROM JSONB_TO_RECORDSET(COALESCE(p_json_data,'[]'::JSONB)) AS x(
        teacher_id INT,
        course_id INT,
        quantity_hours INT,
        status BOOLEAN,
        created_at TIMESTAMP WITH TIME ZONE,
        updated_at TIMESTAMP WITH TIME ZONE
    );

    INSERT INTO teachers_by_course(
        teacher_id,
        course_id,
        quantity_hours,
        status,
        created_at,
        updated_at
    )
    SELECT
        teacher_id,
        COALESCE(course_id, NULL),
        COALESCE(quantity_hours, 0),
        COALESCE(status, TRUE),
        COALESCE(created_at, CURRENT_TIMESTAMP),
        updated_at
    FROM tmp_teachers_by_course;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER COST 1000;

COMMENT ON FUNCTION public.fx_ins_teachers_by_course(JSONB) IS
$$
OBJETIVO : Insertar registros en teachers_by_course
SINTAXIS:
SELECT public.fx_ins_teachers_by_course('[{"teacher_id":1,"course_id":2,"quantity_hours":40}]'::jsonb);
$$;


DROP FUNCTION IF EXISTS public.fx_upd_teachers_by_course(JSONB);
CREATE FUNCTION public.fx_upd_teachers_by_course(JSONB)
RETURNS BOOLEAN
AS $$
DECLARE
    p_json_data ALIAS FOR $1;
BEGIN
    DROP TABLE IF EXISTS tmp_teachers_by_course_upd;
    CREATE TEMPORARY TABLE tmp_teachers_by_course_upd AS
    SELECT
        x.id,
        x.teacher_id,
        x.course_id,
        x.quantity_hours,
        x.status,
        x.updated_at
    FROM JSONB_TO_RECORDSET(COALESCE(p_json_data,'[]'::JSONB)) AS x(
        id INT,
        teacher_id INT,
        course_id INT,
        quantity_hours INT,
        status BOOLEAN,
        updated_at TIMESTAMP WITH TIME ZONE
    );

    UPDATE teachers_by_course t
    SET
        teacher_id = COALESCE(u.teacher_id, t.teacher_id),
        course_id = COALESCE(u.course_id, t.course_id),
        quantity_hours = COALESCE(u.quantity_hours, t.quantity_hours),
        status = COALESCE(u.status, t.status),
        updated_at = COALESCE(u.updated_at, CURRENT_TIMESTAMP)
    FROM tmp_teachers_by_course_upd u
    WHERE t.id = u.id;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER COST 1000;

COMMENT ON FUNCTION public.fx_upd_teachers_by_course(JSONB) IS
$$
OBJETIVO : Actualizar teachers_by_course (parcial)
SINTAXIS:
SELECT public.fx_upd_teachers_by_course('[{"id":1,"quantity_hours":50}]'::jsonb);
$$;


-- ******************************************************************
-- ENROLLMENTS
-- ******************************************************************
DROP FUNCTION IF EXISTS public.fx_sel_enrollments(JSONB);
CREATE FUNCTION public.fx_sel_enrollments(JSONB)
RETURNS TABLE (
    id INT,
    student_id INT,
    student_person_id INT,
    student_dni VARCHAR,
    student_names VARCHAR,
    amount NUMERIC,
    disacount NUMERIC,
    quantity_courses INT,
    status BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
)
AS $$
DECLARE
    p_json_data ALIAS FOR $1;
BEGIN
    RETURN QUERY
    WITH filtros AS (
      SELECT
        x.id,
        x.student_id,
        x.status,
        x.created_at
      FROM JSONB_TO_RECORDSET(COALESCE(p_json_data,'[]'::JSONB)) AS x(
        id INT,
        student_id INT,
        status BOOLEAN,
        created_at TIMESTAMP WITH TIME ZONE
      )
    )
    SELECT
      e.id,
      e.student_id,
      s.person_id as student_person_id,
      p.dni as student_dni,
      p.names as student_names,
      e.amount,
      e.disacount,
      e.quantity_courses,
      e.status,
      e.created_at,
      e.updated_at
    FROM enrollments e
    LEFT JOIN students s ON s.id = e.student_id
    LEFT JOIN people p ON p.id = s.person_id
    LEFT JOIN filtros f ON TRUE
    WHERE (f.id IS NULL OR e.id = f.id)
      AND (f.student_id IS NULL OR e.student_id = f.student_id)
      AND (f.status IS NULL OR e.status = f.status)
      AND (f.created_at IS NULL OR DATE(e.created_at) = DATE(f.created_at));
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER COST 1000;

COMMENT ON FUNCTION public.fx_sel_enrollments(JSONB) IS
$$
OBJETIVO : Consultar enrollments (join students->people)
SINTAXIS:
SELECT * FROM public.fx_sel_enrollments(NULL);
SELECT * FROM public.fx_sel_enrollments('[{"student_id":1}]'::jsonb);
$$;


DROP FUNCTION IF EXISTS public.fx_ins_enrollments(JSONB);
CREATE FUNCTION public.fx_ins_enrollments(JSONB)
RETURNS TABLE (
    id INT
)
AS $$
DECLARE
    p_json_data ALIAS FOR $1;
BEGIN
    DROP TABLE IF EXISTS tmp_enrollments;
    CREATE TEMPORARY TABLE tmp_enrollments AS
    SELECT
        x.student_id,
        x.amount,
        x.disacount,
        x.quantity_courses,
        x.status,
        x.created_at,
        x.updated_at
    FROM JSONB_TO_RECORDSET(COALESCE(p_json_data,'[]'::JSONB)) AS x(
        student_id INT,
        amount NUMERIC,
        disacount NUMERIC,
        quantity_courses INT,
        status BOOLEAN,
        created_at TIMESTAMP WITH TIME ZONE,
        updated_at TIMESTAMP WITH TIME ZONE
    );

    RETURN QUERY
    INSERT INTO enrollments(
        student_id,
        amount,
        disacount,
        quantity_courses,
        status,
        created_at,
        updated_at
    )
    SELECT
        student_id,
        COALESCE(amount, 0),
        COALESCE(disacount, 0),
        COALESCE(quantity_courses, 0),
        COALESCE(status, TRUE),
        COALESCE(created_at, CURRENT_TIMESTAMP),
        updated_at
    FROM tmp_enrollments
    RETURNING id;
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER COST 1000;

COMMENT ON FUNCTION public.fx_ins_enrollments(JSONB) IS
$$
OBJETIVO : Insertar enrollments (puede insertar varios registros desde arreglo JSON)
SINTAXIS:
SELECT * FROM public.fx_ins_enrollments('[{"student_id":1,"amount":200.00,"disacount":10.00,"quantity_courses":2}]'::jsonb);
$$;


DROP FUNCTION IF EXISTS public.fx_upd_enrollments(JSONB);
CREATE FUNCTION public.fx_upd_enrollments(JSONB)
RETURNS BOOLEAN
AS $$
DECLARE
    p_json_data ALIAS FOR $1;
BEGIN
    DROP TABLE IF EXISTS tmp_enrollments_upd;
    CREATE TEMPORARY TABLE tmp_enrollments_upd AS
    SELECT
        x.id,
        x.student_id,
        x.amount,
        x.disacount,
        x.quantity_courses,
        x.status,
        x.updated_at
    FROM JSONB_TO_RECORDSET(COALESCE(p_json_data,'[]'::JSONB)) AS x(
        id INT,
        student_id INT,
        amount NUMERIC,
        disacount NUMERIC,
        quantity_courses INT,
        status BOOLEAN,
        updated_at TIMESTAMP WITH TIME ZONE
    );

    UPDATE enrollments e
    SET
        student_id = COALESCE(u.student_id, e.student_id),
        amount = COALESCE(u.amount, e.amount),
        disacount = COALESCE(u.disacount, e.disacount),
        quantity_courses = COALESCE(u.quantity_courses, e.quantity_courses),
        status = COALESCE(u.status, e.status),
        updated_at = COALESCE(u.updated_at, CURRENT_TIMESTAMP)
    FROM tmp_enrollments_upd u
    WHERE e.id = u.id;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER COST 1000;

COMMENT ON FUNCTION public.fx_upd_enrollments(JSONB) IS
$$
OBJETIVO : Actualizar enrollments (parcial)
SINTAXIS:
SELECT public.fx_upd_enrollments('[{"id":1,"amount":180.00}]'::jsonb);
$$;


-- ******************************************************************
-- ENROLLMENT_DETAILS
-- ******************************************************************
DROP FUNCTION IF EXISTS public.fx_sel_enrollment_details(JSONB);
CREATE FUNCTION public.fx_sel_enrollment_details(JSONB)
RETURNS TABLE (
    id INT,
    enrollment_id INT,
    course_assigned_id INT,
    course_name VARCHAR,
    teacher_person_id INT,
    teacher_dni VARCHAR,
    teacher_names VARCHAR,
    score NUMERIC,
    status BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
)
AS $$
DECLARE
    p_json_data ALIAS FOR $1;
BEGIN
    RETURN QUERY
    WITH filtros AS (
      SELECT
        x.id,
        x.enrollment_id,
        x.course_assigned_id,
        x.status,
        x.created_at
      FROM JSONB_TO_RECORDSET(COALESCE(p_json_data,'[]'::JSONB)) AS x(
        id INT,
        enrollment_id INT,
        course_assigned_id INT,
        status BOOLEAN,
        created_at TIMESTAMP WITH TIME ZONE
      )
    )
    SELECT
      ed.id,
      ed.enrollment_id,
      ed.course_assigned_id,
      c.name as course_name,
      te.person_id as teacher_person_id,
      p.dni as teacher_dni,
      p.names as teacher_names,
      ed.score,
      ed.status,
      ed.created_at,
      ed.updated_at
    FROM enrollment_details ed
    LEFT JOIN teachers_by_course tbc ON tbc.id = ed.course_assigned_id
    LEFT JOIN teachers te ON te.id = tbc.teacher_id
    LEFT JOIN people p ON p.id = te.person_id
    LEFT JOIN courses c ON c.id = tbc.course_id
    LEFT JOIN filtros f ON TRUE
    WHERE (f.id IS NULL OR ed.id = f.id)
      AND (f.enrollment_id IS NULL OR ed.enrollment_id = f.enrollment_id)
      AND (f.course_assigned_id IS NULL OR ed.course_assigned_id = f.course_assigned_id)
      AND (f.status IS NULL OR ed.status = f.status)
      AND (f.created_at IS NULL OR DATE(ed.created_at) = DATE(f.created_at));
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER COST 1000;

COMMENT ON FUNCTION public.fx_sel_enrollment_details(JSONB) IS
$$
OBJETIVO : Consultar enrollment_details con joins a teachers_by_course->teachers->people y courses
SINTAXIS:
SELECT * FROM public.fx_sel_enrollment_details(NULL);
SELECT * FROM public.fx_sel_enrollment_details('[{"enrollment_id":1}]'::jsonb);
$$;


DROP FUNCTION IF EXISTS public.fx_ins_enrollment_details(JSONB);
CREATE FUNCTION public.fx_ins_enrollment_details(JSONB)
RETURNS BOOLEAN
AS $$
DECLARE
    p_json_data ALIAS FOR $1;
BEGIN
    DROP TABLE IF EXISTS tmp_enrollment_details;
    CREATE TEMPORARY TABLE tmp_enrollment_details AS
    SELECT
        x.enrollment_id,
        x.course_assigned_id,
        x.score,
        x.status,
        x.created_at,
        x.updated_at
    FROM JSONB_TO_RECORDSET(COALESCE(p_json_data,'[]'::JSONB)) AS x(
        enrollment_id INT,
        course_assigned_id INT,
        score NUMERIC,
        status BOOLEAN,
        created_at TIMESTAMP WITH TIME ZONE,
        updated_at TIMESTAMP WITH TIME ZONE
    );

    INSERT INTO enrollment_details(
        enrollment_id,
        course_assigned_id,
        score,
        status,
        created_at,
        updated_at
    )
    SELECT
        enrollment_id,
        course_assigned_id,
        COALESCE(score, NULL),
        COALESCE(status, TRUE),
        COALESCE(created_at, CURRENT_TIMESTAMP),
        updated_at
    FROM tmp_enrollment_details;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER COST 1000;

COMMENT ON FUNCTION public.fx_ins_enrollment_details(JSONB) IS
$$
OBJETIVO : Insertar registros en enrollment_details
SINTAXIS:
SELECT public.fx_ins_enrollment_details('[{"enrollment_id":1,"course_assigned_id":2,"score":15.5}]'::jsonb);
$$;


DROP FUNCTION IF EXISTS public.fx_upd_enrollment_details(JSONB);
CREATE FUNCTION public.fx_upd_enrollment_details(JSONB)
RETURNS BOOLEAN
AS $$
DECLARE
    p_json_data ALIAS FOR $1;
BEGIN
    DROP TABLE IF EXISTS tmp_enrollment_details_upd;
    CREATE TEMPORARY TABLE tmp_enrollment_details_upd AS
    SELECT
        x.id,
        x.enrollment_id,
        x.course_assigned_id,
        x.score,
        x.status,
        x.updated_at
    FROM JSONB_TO_RECORDSET(COALESCE(p_json_data,'[]'::JSONB)) AS x(
        id INT,
        enrollment_id INT,
        course_assigned_id INT,
        score NUMERIC,
        status BOOLEAN,
        updated_at TIMESTAMP WITH TIME ZONE
    );

    UPDATE enrollment_details ed
    SET
        enrollment_id = COALESCE(u.enrollment_id, ed.enrollment_id),
        course_assigned_id = COALESCE(u.course_assigned_id, ed.course_assigned_id),
        score = COALESCE(u.score, ed.score),
        status = COALESCE(u.status, ed.status),
        updated_at = COALESCE(u.updated_at, CURRENT_TIMESTAMP)
    FROM tmp_enrollment_details_upd u
    WHERE ed.id = u.id;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER COST 1000;

COMMENT ON FUNCTION public.fx_upd_enrollment_details(JSONB) IS
$$
OBJETIVO : Actualizar enrollment_details (parcial)
SINTAXIS:
SELECT public.fx_upd_enrollment_details('[{"id":1,"score":18}]'::jsonb);
$$;


