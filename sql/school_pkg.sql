CREATE OR REPLACE PACKAGE school_pkg AS

    --Procedures to show every tuple for every table
    --Package spec declares the eight show_* procedures plus a show_all wrapper
    PROCEDURE show_students;
    PROCEDURE show_courses;
    PROCEDURE show_course_credit;
    PROCEDURE show_classes;
    PROCEDURE show_g_enrollments;
    PROCEDURE show_score_grade;
    PROCEDURE show_prerequisites;
    PROCEDURE show_logs;
    PROCEDURE show_all;

    -- Show all students in a class
    PROCEDURE show_class_students (
        p_classid IN VARCHAR2   -- classes.classid is CHAR(5)
    );

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