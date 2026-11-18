CREATE OR REPLACE PACKAGE school_pkg AS

    --Procedures to show every tuple for every table
    --Package spec declares the eight show_* procedures plus a show_all wrapper
    --All 8 Table Display Functions (task 2)
    --Return ref cursor of students for display
    FUNCTION show_students RETURN ref_cursor;

    --Return ref cursor of courses for display
    FUNCTION show_courses RETURN ref_cursor;

    --Return ref cursor of course_credit for display
    FUNCTION show_course_credit RETURN ref_cursor;

    --Return ref cursor of classes for display
    FUNCTION show_classes RETURN ref_cursor;

    --Return ref cursor of g_enrollments for display
    FUNCTION show_g_enrollments RETURN ref_cursor;

    --Return ref cursor of score_grade for display
    FUNCTION show_score_grade RETURN ref_cursor;

    --Return ref cursor of prerequisites for display
    FUNCTION show_prerequisites RETURN ref_cursor;

    --Return ref cursor of logs for display
    FUNCTION show_logs RETURN ref_cursor;

    -- Show names of all tables
    FUNCTION get_table_names RETURN ref_cursor;

    -- Show all students in a class
    FUNCTION show_class_students(
        p_classid IN VARCHAR2
    ) return ref_cursor;

    -- Show all prerequisites of a class
    PROCEDURE get_all_prerequisites (
        p_dept_code IN  VARCHAR2,
        p_course    IN  NUMBER,
        p_result    OUT SYS_REFCURSOR
    );

    -- Enroll a grad student in a class
    PROCEDURE enroll_graduate (
        p_B#      IN VARCHAR2,  -- students.B# is CHAR(9)
        p_classid IN VARCHAR2   -- classes.classid is CHAR(5)
    );

    -- Drop a graduate student from a class
    PROCEDURE drop_graduate (
        p_B#      IN VARCHAR2,  -- students.B# is CHAR(9)
        p_classid IN VARCHAR2   -- classes.classid is CHAR(5)
    );

    -- Delete a student and all of their enrollments
    PROCEDURE delete_student (
        p_B#      IN VARCHAR2   -- students.B# is CHAR(9)
    );

END school_pkg;
/
SHOW ERRORS;