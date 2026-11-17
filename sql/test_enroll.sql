------------------------------------------------------------------
-- Test for Question 4
------------------------------------------------------------------
DECLARE
    -- Declarations: variables used by the block
    v_cur    SYS_REFCURSOR;                     -- cursor to receive the result set
    v_dept   prerequisites.dept_code%TYPE := 'CS';   -- testing input: department
    v_course prerequisites.course#%TYPE   := 532;    -- testing input: course number

    -- Local helper: runs the procedure, prints rows, handles errors
    PROCEDURE show_prereqs (p_dept IN classes.dept_code%TYPE, 
                            p_course IN classes.course#%TYPE) IS
        l_cur SYS_REFCURSOR;
        l_val VARCHAR2(30);
        l_rows PLS_INTEGER := 0;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('--- Prerequisites for '
                             || p_dept || p_course || ' ---');

        -- May raise ORA-20001 (course doesn't exist) or other errors
        school_pkg.get_all_prerequisites(p_dept, p_course, l_cur);

        -- Only reached if the procedure opened the cursor successfully
        LOOP
            FETCH l_cur INTO v_dept, v_course;
            EXIT WHEN l_cur%NOTFOUND;
            DBMS_OUTPUT.PUT_LINE('  ' || l_val);
            l_rows := l_rows + 1;
        END LOOP;
        CLOSE l_cur;

        IF l_rows = 0 THEN
            DBMS_OUTPUT.PUT_LINE('  (no prerequisites)');
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            -- Close the cursor if it was opened before the error
            IF l_cur%ISOPEN THEN
                CLOSE l_cur;
            END IF;

            IF SQLCODE = -20001 THEN
                -- Our own validation error: report and continue
                DBMS_OUTPUT.PUT_LINE('  [invalid course] ' || SQLERRM);
            ELSE
                -- Unexpected error: report and re-raise
                DBMS_OUTPUT.PUT_LINE('  [unexpected error] ' || SQLERRM);
                RAISE;
            END IF;
    END show_prereqs;

BEGIN
    -- single-level prereq: CS240 is the only prerequisite of CS536
    show_prereqs('CS', 536);   -- -> CS240

    -- two-level chain: CS532 -> CS432 -> CS240
    show_prereqs('CS', 532);   -- -> CS432, CS240

    -- multiple prereqs + depth: CS575 -> Math314 and CS240
    show_prereqs('CS', 575);   -- -> Math314, CS240

    -- same course as the new c0010 class, confirms graph not section
    show_prereqs('CS', 550);   -- -> CS240

    -- no prerequisites at all (leaf course) -> exercises the empty result
    show_prereqs('CS', 240);   -- -> (no prerequisites)

    -- undergrad 4-credit course, also a leaf
    show_prereqs('Math', 314); -- -> (no prerequisites)

    -- invalid course number
    show_prereqs('CS', 999);   -- -> ORA-20001 caught

    -- invalid department
    show_prereqs('XX', 432);   -- -> ORA-20001 caught

EXCEPTION
    -- Exception section: last line of defense for unexpected errors
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('FATAL: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
END;
/


------------------------------------------------------------------
-- Test for Question 5
------------------------------------------------------------------
DECLARE
    PROCEDURE try_enroll (p_B IN CHAR, p_cid IN CHAR) IS
    BEGIN
        school_pkg.enroll_graduate(p_B, p_cid);
        DBMS_OUTPUT.PUT_LINE('OK    ' || p_B || ' -> ' || p_cid);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('FAIL  ' || p_B || ' -> ' || p_cid
                                 || ' : ' || SQLERRM);
    END;

    ------------------------------------------------------------------
    -- Snapshot helpers
    ------------------------------------------------------------------
    PROCEDURE snap_class (p_cid IN CHAR, p_label IN VARCHAR2) IS
        l_size  classes.class_size%TYPE;
        l_limit classes.limit%TYPE;
    BEGIN
        SELECT class_size, limit INTO l_size, l_limit
        FROM classes WHERE classid = p_cid;
        DBMS_OUTPUT.PUT_LINE('    [' || p_label || '] '
                             || p_cid || ' size=' || l_size || '/' || l_limit);
    END;

    PROCEDURE snap_enroll_count (p_B IN g_enrollments.g_B#%TYPE,
                                p_cid IN g_enrollments.classid%TYPE,
                                p_label IN VARCHAR2) IS
        l_cnt NUMBER;
    BEGIN
        SELECT COUNT(*) INTO l_cnt
        FROM g_enrollments
        WHERE g_B# = p_B AND classid = p_cid;
        DBMS_OUTPUT.PUT_LINE('    [' || p_label || '] '
                             || p_B || ' in ' || p_cid || ' = ' || l_cnt
                             || ' row(s)');
    END;

    PROCEDURE show_class_after (p_cid IN CHAR) IS
    BEGIN
        snap_class(p_cid, 'after');
    END;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== -20011: invalid B# ===');
    try_enroll('B99999999', 'c0008');

    DBMS_OUTPUT.PUT_LINE('=== -20012: not a graduate student ===');
    try_enroll('B00000012', 'c0008');

    DBMS_OUTPUT.PUT_LINE('=== -20013: invalid classid ===');
    try_enroll('B00000008', 'c9999');

    DBMS_OUTPUT.PUT_LINE('=== -20014: previous semester ===');
    try_enroll('B00000008', 'c0006');   -- Spring 2026
    try_enroll('B00000008', 'c0011');   -- Spring 2026
    try_enroll('B00000008', 'c0007');   -- Spring 2025
    try_enroll('B00000008', 'c0001');   -- Spring 2027

    DBMS_OUTPUT.PUT_LINE('=== -20015: class already full ===');
    snap_class('c0009', 'before');
    try_enroll('B00000008', 'c0009');
    snap_class('c0009', 'after');       -- should be UNCHANGED

    DBMS_OUTPUT.PUT_LINE('=== -20016: already enrolled ===');
    snap_class('c0002', 'before');
    try_enroll('B00000001', 'c0002');
    snap_class('c0002', 'after');       -- should be UNCHANGED

    DBMS_OUTPUT.PUT_LINE('=== -20018: prerequisite not satisfied ===');
    snap_class('c0012', 'before');
    try_enroll('B00000008', 'c0012');
    snap_class('c0012', 'after');       -- should be UNCHANGED

    ------------------------------------------------------------------
    -- SUCCESS + trigger verification
    ------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('=== SUCCESS: B00000008 -> c0008 (CS240, no prereqs) ===');
    snap_class('c0008', 'before');
    snap_enroll_count('B00000008', 'c0008', 'before');
    try_enroll('B00000008', 'c0008');
    snap_class('c0008', 'after');       -- EXPECT +1
    snap_enroll_count('B00000008', 'c0008', 'after');  -- EXPECT 1

    -- Verify the new row's score is NULL and the PK is in place
    DECLARE
        l_score g_enrollments.score%TYPE;
    BEGIN
        SELECT score INTO l_score
          FROM g_enrollments
         WHERE g_B# = 'B00000008' AND classid = 'c0008';
        DBMS_OUTPUT.PUT_LINE('    new row score = '
                             || NVL(TO_CHAR(l_score), 'NULL'));
    END;

    ------------------------------------------------------------------
    -- Second success on a different class -> independent trigger fire
    ------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('=== SUCCESS: B00000008 -> c0002 (Math314, no prereqs) ===');
    snap_class('c0002', 'before');
    snap_enroll_count('B00000008', 'c0002', 'before');
    try_enroll('B00000008', 'c0002');
    snap_class('c0002', 'after');       -- EXPECT +1
    snap_enroll_count('B00000008', 'c0002', 'after');  -- EXPECT 1

    ------------------------------------------------------------------
    -- Duplicate attempt after success -> -20016, size must NOT move
    ------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('=== -20016 after success: repeat B00000008 -> c0008 ===');
    snap_class('c0008', 'before');
    try_enroll('B00000008', 'c0008');
    snap_class('c0008', 'after');       -- EXPECT UNCHANGED (still 11)
END;
/
/

------------------------------------------------------------------
-- Test triggers
------------------------------------------------------------------
select * from logs;