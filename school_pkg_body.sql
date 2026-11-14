CREATE OR REPLACE PACKAGE BODY school_pkg AS

    ------------------------------------------------------------------
    -- 4. Get a class's prerequisites
    ------------------------------------------------------------------
    PROCEDURE get_all_prerequisites (
        p_dept_code IN  classes.dept_code%TYPE,
        p_course    IN  classes.course#%TYPE,
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
    -- 5. Enroll and graduate student into a class
    ------------------------------------------------------------------
    PROCEDURE enroll_graduate (
        p_B#      IN g_enrollments.g_B#%TYPE,
        p_classid IN classes.classid%TYPE
    ) AS
        v_st_level   students.st_level%TYPE;
        v_dept_code  classes.dept_code%TYPE;
        v_course#    classes.course#%TYPE;
        v_year       classes.year%TYPE;
        v_semester   classes.semester%TYPE;
        v_limit      classes.limit%TYPE;
        v_size       classes.class_size%TYPE;
        v_cnt        NUMBER;
        v_enrolled   NUMBER;
        v_missing    NUMBER;
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
            SELECT dept_code, course#, year, semester, limit, class_size
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
            v_cur_semester classes.semester%TYPE;
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
            v_pre       VARCHAR2(20);
            v_pre_dept  prerequisites.dept_code%TYPE;
            v_pre_crs   prerequisites.course#%TYPE;
            v_grade     score_grade.lgrade%TYPE;
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
                        v_missing := v_missing || v_pre || ', ';
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

END school_pkg;
/