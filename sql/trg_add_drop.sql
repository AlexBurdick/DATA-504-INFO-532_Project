-- Trigger for student delete
-- BEFORE DELETE (not AFTER) so enrollments are removed before the
-- foreign key check on g_enrollments.g_B# fires (avoids ORA-02292 / ORA-04091)
CREATE OR REPLACE TRIGGER trg_student_delete
BEFORE DELETE ON students
FOR EACH ROW
BEGIN
    -- Cascade delete all enrollments for this student
    DELETE FROM g_enrollments WHERE g_B# = :OLD.B#;

    -- Records the student table deletion in logs table
    INSERT INTO logs VALUES (
        log_seq.NEXTVAL,
        USER,
        SYSDATE,
        'students',
        'delete',
        :OLD.B#
    );
END;
/
SHOW ERRORS;

-- Trigger for enrolling in a class (insert into g_enrollments)
CREATE OR REPLACE TRIGGER trg_g_enroll_insert
AFTER INSERT ON g_enrollments
FOR EACH ROW
BEGIN
    -- Update class size count for enrolled class
    UPDATE classes
    SET class_size = class_size + 1
    WHERE classid = :NEW.classid;

    -- Record transaction in logs table using sequence and composite key
    INSERT INTO logs VALUES (
        log_seq.NEXTVAL,
        USER,
        SYSDATE,
        'g_enrollments',
        'insert',
        :NEW.g_B# || ',' || :NEW.classid
    );
END;
/
SHOW ERRORS;

-- Trigger for student dropping a class (delete from g_enrollments)
CREATE OR REPLACE TRIGGER trg_g_enroll_delete
AFTER DELETE ON g_enrollments
FOR EACH ROW
BEGIN
    -- Update class size count for dropped class
    UPDATE classes
    SET class_size = class_size - 1
    WHERE classid = :OLD.classid;

    -- Record transaction in the logs table
    INSERT INTO logs VALUES (
        log_seq.NEXTVAL,
        USER,
        SYSDATE,
        'g_enrollments',
        'delete',
        :OLD.g_B# || ',' || :OLD.classid
    );
END;
/
SHOW ERRORS;