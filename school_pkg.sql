CREATE OR REPLACE PACKAGE school_pkg AS

    PROCEDURE get_all_prerequisites (
        p_dept_code IN  classes.dept_code%TYPE,
        p_course    IN  classes.course#%TYPE,
        p_result    OUT SYS_REFCURSOR
    );

    PROCEDURE enroll_graduate (
        p_B#      IN g_enrollments.g_B#%TYPE,
        p_classid IN g_enrollments.classid%TYPE
    );

END school_pkg;
/