CREATE OR REPLACE PACKAGE BODY school_pkg AS

    ------------------------------------------------------------------
    -- 2. Show tuples for every table
    ------------------------------------------------------------------
        -- Show every row in students
    PROCEDURE show_students IS
    BEGIN
        FOR s IN (SELECT * FROM students) LOOP
            DBMS_OUTPUT.PUT_LINE(
                s.B# || ' ' || s.first_name || ' ' ||
                s.last_name || ' ' || s.st_level || ' ' ||
                s.gpa || ' ' || s.email || ' ' || s.bdate
            );
        END LOOP;
    END show_students;

    -- Show every row in courses
    PROCEDURE show_courses IS
    BEGIN
        FOR c IN (SELECT * FROM courses) LOOP
            DBMS_OUTPUT.PUT_LINE(
                c.dept_code || ' ' || c.course# || ' ' || c.title
            );
        END LOOP;
    END show_courses;

    -- Show every row in course_credit
    PROCEDURE show_course_credit IS
    BEGIN
        FOR c IN (SELECT * FROM course_credit) LOOP
            DBMS_OUTPUT.PUT_LINE(
                c.course# || ' ' || c.credits
            );
        END LOOP;
    END show_course_credit;

    -- Show every row in classes
    PROCEDURE show_classes IS
    BEGIN
        FOR c IN (SELECT * FROM classes) LOOP
            DBMS_OUTPUT.PUT_LINE(
                c.classid || ' ' || c.dept_code || ' ' ||
                c.course# || ' ' || c.sect# || ' ' ||
                c.year || ' ' || c.semester || ' ' ||
                c."LIMIT" || ' ' || c.class_size || ' ' ||
                c.room
            );
        END LOOP;
    END show_classes;

    -- Show every row in g_enrollments
    PROCEDURE show_g_enrollments IS
    BEGIN
        FOR e IN (SELECT * FROM g_enrollments) LOOP
            DBMS_OUTPUT.PUT_LINE(
                e.g_B# || ' ' || e.classid || ' ' || e.score
            );
        END LOOP;
    END show_g_enrollments;

    -- Show every row in score_grade
    PROCEDURE show_score_grade IS
    BEGIN
        FOR s IN (SELECT * FROM score_grade) LOOP
            DBMS_OUTPUT.PUT_LINE(
                s.score || ' ' || s.lgrade
            );
        END LOOP;
    END show_score_grade;

    -- Show every row in prerequisites
    PROCEDURE show_prerequisites IS
    BEGIN
        FOR p IN (SELECT * FROM prerequisites) LOOP
            DBMS_OUTPUT.PUT_LINE(
                p.dept_code || ' ' || p.course# || ' ' ||
                p.pre_dept_code || ' ' || p.pre_course#
            );
        END LOOP;
    END show_prerequisites;

    -- Show every row in logs
    PROCEDURE show_logs IS
    BEGIN
        FOR l IN (SELECT * FROM logs) LOOP
            DBMS_OUTPUT.PUT_LINE(
                l.log# || ' ' || l.user_name || ' ' ||
                l.op_time || ' ' || l.table_name || ' ' ||
                l.operation || ' ' || l.tuple_keyvalue
            );
        END LOOP;
    END show_logs;

    -- Dump every table in dependency order
    PROCEDURE show_all IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE('=== students ===');
        show_students;

        DBMS_OUTPUT.PUT_LINE('=== courses ===');
        show_courses;

        DBMS_OUTPUT.PUT_LINE('=== course_credit ===');
        show_course_credit;

        DBMS_OUTPUT.PUT_LINE('=== classes ===');
        show_classes;

        DBMS_OUTPUT.PUT_LINE('=== g_enrollments ===');
        show_g_enrollments;

        DBMS_OUTPUT.PUT_LINE('=== score_grade ===');
        show_score_grade;

        DBMS_OUTPUT.PUT_LINE('=== prerequisites ===');
        show_prerequisites;

        DBMS_OUTPUT.PUT_LINE('=== logs ===');
        show_logs;
    END show_all;

    ------------------------------------------------------------------
    -- 3. Show all students in a class
    ------------------------------------------------------------------
    PROCEDURE show_class_students (
        p_classid IN CHAR(5)   -- classes.classid is CHAR(5)
    ) AS
        class_count NUMBER;
    BEGIN
        --check if classid exists in classes table
        SELECT COUNT(*) INTO class_count
        FROM classes
        WHERE classid = p_classid;

        IF class_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20031,
                'The classid is invalid.');
        END IF;

        --print a header so the output is self-describing
        DBMS_OUTPUT.PUT_LINE('Students in ' || p_classid || ':');

        --list every student enrolled in the class
        FOR s IN (
            SELECT students.B#, students.first_name, students.last_name
            FROM students
            JOIN g_enrollments
                ON students.B# = g_enrollments.g_B#
            WHERE g_enrollments.classid = p_classid
        ) LOOP
            DBMS_OUTPUT.PUT_LINE(
                s.B# || ' ' || s.first_name || ' ' || s.last_name
            );
        END LOOP;
    END show_class_students;

    ------------------------------------------------------------------
    -- 4. Get a class's prerequisites
    ------------------------------------------------------------------
    PROCEDURE get_all_prerequisites (
        p_dept_code IN  VARCHAR2,
        p_course    IN  NUMBER,
        p_result    OUT SYS_REFCURSOR
    ) AS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count
        FROM courses
        WHERE dept_code = p_dept_code AND course# = p_course;

        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 
                p_dept_code || p_course || ' does not exist.');
        END IF;

        OPEN p_result FOR
            WITH all_prereqs (pre_dept_code, pre_course#) AS (
                SELECT pre_dept_code, pre_course#
                FROM prerequisites
                WHERE dept_code = p_dept_code AND course# = p_course
                UNION ALL
                SELECT p.pre_dept_code, p.pre_course#
                FROM prerequisites p
                JOIN all_prereqs  a
                    ON p.dept_code = a.pre_dept_code
                    AND p.course#   = a.pre_course#
            )
            SELECT DISTINCT pre_dept_code, pre_course#
            FROM all_prereqs;
    END get_all_prerequisites;

    ------------------------------------------------------------------
    -- 5. Enroll a graduate student into a class
    ------------------------------------------------------------------
    PROCEDURE enroll_graduate (
        p_B#      IN CHAR,
        p_classid IN CHAR
    ) AS
        v_st_level   VARCHAR2(10);     -- students.st_level
        v_dept_code  VARCHAR2(4);      -- classes.dept_code
        v_course#    NUMBER;           -- classes.course#
        v_year       NUMBER;           -- classes.year
        v_semester   VARCHAR2(8);      -- classes.semester
        v_limit      NUMBER;           -- classes."LIMIT"
        v_size       NUMBER;           -- classes.class_size
        v_cnt        NUMBER;
        v_enrolled   NUMBER;
    BEGIN
        -- B# must exist
        BEGIN
            SELECT st_level INTO v_st_level
            FROM students
            WHERE B# = p_B#;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20011, 'The B# is invalid.');
        END;

        -- Must be a graduate student
        IF v_st_level NOT IN ('master', 'PhD') THEN
            RAISE_APPLICATION_ERROR(-20012,
                'This is not a graduate student.');
        END IF;

        -- classid must exist
        BEGIN
            SELECT dept_code, course#, year, semester, "LIMIT", class_size
            INTO v_dept_code, v_course#, v_year, v_semester, v_limit, v_size
            FROM classes
            WHERE classid = p_classid;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20013,
                    'The classid is invalid.');
        END;

        -- Class must be offered in the current semester
        DECLARE
            -- Current term is derived from SYSDATE.
            v_cur_year     NUMBER := EXTRACT(YEAR  FROM SYSDATE);
            v_cur_month    NUMBER := EXTRACT(MONTH FROM SYSDATE);
            v_cur_semester VARCHAR2(8);
        BEGIN
            v_cur_semester :=
                CASE
                    WHEN v_cur_month BETWEEN 1 AND 4  THEN 'Spring'
                    WHEN v_cur_month BETWEEN 5 AND 6  THEN 'Summer 1'
                    WHEN v_cur_month BETWEEN 7 AND 8  THEN 'Summer 2'
                    WHEN v_cur_month BETWEEN 9 AND 12 THEN 'Fall'
                END;

            IF NOT (v_semester = v_cur_semester AND v_year = v_cur_year) THEN
                RAISE_APPLICATION_ERROR(-20014,
                    'Cannot enroll into a class from a previous semester.');
            END IF;
        END;

        -- Class must not already be full
        IF v_size >= v_limit THEN
            RAISE_APPLICATION_ERROR(-20015,
                'The class is already full.');
        END IF;

        -- Student must not already be in this class
        SELECT COUNT(*) INTO v_enrolled
        FROM g_enrollments
        WHERE g_B# = p_B# AND classid = p_classid;

        IF v_enrolled > 0 THEN
            RAISE_APPLICATION_ERROR(-20016,
                'The student is already in the class.');
        END IF;

        -- Student must not already have 5 classes this semester/year
        SELECT COUNT(*) INTO v_cnt
        FROM g_enrollments e
        JOIN classes c ON e.classid = c.classid
        WHERE e.g_B#       = p_B#
            AND c.year     = v_year
            AND c.semester = v_semester;

        IF v_cnt >= 5 THEN
            RAISE_APPLICATION_ERROR(-20017,
                'Students cannot be enrolled in more than five classes in the same semester.');
        END IF;

        -- Prerequisites must all be completed with at least C
        DECLARE
            v_pre_cur   SYS_REFCURSOR;    -- cursor from get_all_prerequisites
            v_pre_dept  VARCHAR2(4);      -- prerequisites.dept_code
            v_pre_crs   NUMBER;           -- prerequisites.course#
            v_grade     VARCHAR2(2);      -- score_grade.lgrade
            v_missing   VARCHAR2(4000) := '';   -- collect unsatisfied prereqs
        BEGIN
            -- Ask the existing procedure for the full prereq list
            get_all_prerequisites(v_dept_code, v_course#, v_pre_cur);

            LOOP
                FETCH v_pre_cur INTO v_pre_dept, v_pre_crs;
                EXIT WHEN v_pre_cur%NOTFOUND;

                -- Did the student pass this prerequisite with >= C?
                BEGIN
                    SELECT sg.lgrade INTO v_grade
                    FROM g_enrollments e
                    JOIN classes c ON e.classid = c.classid
                    JOIN score_grade sg ON e.score = sg.score
                    WHERE e.g_B# = p_B#
                        AND c.dept_code = v_pre_dept
                        AND c.course#   = v_pre_crs
                        AND sg.lgrade   IN ('A','A-','B+','B','B-','C+','C');

                    -- Found a passing grade -> prerequisite satisfied
                    NULL;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        -- Either never took it, or took it but grade < C
                        v_missing := v_missing || v_pre_dept || v_pre_crs || ', ';
                END;
            END LOOP;

            CLOSE v_pre_cur;

            IF v_missing IS NOT NULL THEN
                RAISE_APPLICATION_ERROR(-20018,
                    'Prerequisite not satisfied: ' || RTRIM(v_missing, ', '));
            END IF;

        EXCEPTION
            WHEN OTHERS THEN
                IF v_pre_cur%ISOPEN THEN
                    CLOSE v_pre_cur;
                END IF;
                RAISE;
        END;

        -- All checks passed: insert. The AFTER INSERT trigger
        -- (trg_enroll_inc_class_size) bumps classes.class_size.
        INSERT INTO g_enrollments (g_B#, classid, score)
        VALUES (p_B#, p_classid, NULL);

        COMMIT;
    END enroll_graduate;

    ------------------------------------------------------------------
    -- 6. Drop a graduate student from a class
    ------------------------------------------------------------------
    PROCEDURE drop_graduate (
        p_B#      IN CHAR(9),
        p_classid IN CHAR(5)
    ) IS
        -- Local variables for checking
        v_count       NUMBER;
        v_st_level    VARCHAR2(10);      -- students.st_level
        v_semester    VARCHAR2(8);       -- classes.semester
        v_year        NUMBER;            -- classes.year
        v_class_count NUMBER;
        -- Current term (derived from SYSDATE)
        v_cur_year     NUMBER;
        v_cur_month    NUMBER;
        v_cur_semester VARCHAR2(8);

    BEGIN
        -- Check if student exists in students table
        SELECT COUNT(*)
        INTO v_count
        FROM students
        WHERE B# = p_B#;

        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20021,
                'The B# is invalid.');
        END IF;

        -- Check if student is a graduate student (master or PhD)
        SELECT st_level
        INTO v_st_level
        FROM students
        WHERE B# = p_B#;

        IF v_st_level NOT IN ('master', 'PhD') THEN
            RAISE_APPLICATION_ERROR(-20022,
                'This is not a graduate student.');
        END IF;

        -- Check if classid exists in classes table
        SELECT COUNT(*)
        INTO v_count
        FROM classes
        WHERE classid = p_classid;

        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20023,
                'The classid is invalid.');
        END IF;

        -- Check if student is actually enrolled in the class
        SELECT COUNT(*)
        INTO v_count
        FROM g_enrollments
        WHERE g_B# = p_B# AND classid = p_classid;

        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20024,
                'The student is not enrolled in the class.');
        END IF;

        -- Derive the current term from SYSDATE
        v_cur_year  := EXTRACT(YEAR  FROM SYSDATE);
        v_cur_month := EXTRACT(MONTH FROM SYSDATE);
        v_cur_semester :=
            CASE
                WHEN v_cur_month BETWEEN 1 AND 4  THEN 'Spring'
                WHEN v_cur_month BETWEEN 5 AND 6  THEN 'Summer 1'
                WHEN v_cur_month BETWEEN 7 AND 8  THEN 'Summer 2'
                WHEN v_cur_month BETWEEN 9 AND 12 THEN 'Fall'
            END;

        -- Check if class is offered in the current semester
        SELECT semester, year
        INTO v_semester, v_year
        FROM classes
        WHERE classid = p_classid;

        IF v_semester != v_cur_semester OR v_year != v_cur_year THEN
            RAISE_APPLICATION_ERROR(-20025, 
                'Only enrollment in the current semester can be dropped.');
        END IF;

        -- Check if this is the last class for the student in the current semester
        SELECT COUNT(*)
        INTO v_class_count
        FROM g_enrollments ge, classes c
        WHERE ge.g_B#    = p_B#
            AND ge.classid = c.classid
            AND c.semester = v_cur_semester
            AND c.year     = v_cur_year;

        IF v_class_count = 1 THEN
            RAISE_APPLICATION_ERROR(-20026, 
                'This is the only class for this student in the current semester and cannot be dropped.');
        END IF;

        -- All checks pass, delete the enrollment
        -- Triggers will automatically update class size and write to logs table
        DELETE FROM g_enrollments
        WHERE g_B# = p_B#
            AND classid = p_classid;
            
        DBMS_OUTPUT.PUT_LINE('Student successfully dropped from class.');

    END drop_student;

    ------------------------------------------------------------------
    -- 7. Delete a student (cascades to enrollments via trg_student_delete)
    ------------------------------------------------------------------
    PROCEDURE delete_student (
        p_B# IN CHAR(9)
    ) AS
        v_count NUMBER;
    BEGIN
        -- B# must exist
        SELECT COUNT(*) INTO v_count
        FROM students
        WHERE B# = p_B#;

        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20041, 
                'The B# is invalid.');
        END IF;

        -- Delete the student. The BEFORE DELETE trigger on students
        -- (trg_student_delete) removes the enrollments and writes the log.
        DELETE FROM students WHERE B# = p_B#;

        DBMS_OUTPUT.PUT_LINE('Student ' || p_B# || ' deleted successfully.');
    END delete_student;

END school_pkg;
/