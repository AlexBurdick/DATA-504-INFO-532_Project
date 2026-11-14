CREATE OR REPLACE TRIGGER trg_enroll_inc_class_size
AFTER INSERT ON g_enrollments
FOR EACH ROW
BEGIN
    UPDATE classes
       SET class_size = class_size + 1
     WHERE classid = :NEW.classid;
END;
/

CREATE OR REPLACE TRIGGER trg_enroll_dec_class_size
AFTER DELETE ON g_enrollments
FOR EACH ROW
BEGIN
    UPDATE classes
       SET class_size = class_size - 1
     WHERE classid = :OLD.classid;
END;
/
