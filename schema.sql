WHENEVER SQLERROR CONTINUE
DROP TABLE logs CASCADE CONSTRAINTS;
DROP TABLE prerequisites CASCADE CONSTRAINTS;
DROP TABLE score_grade CASCADE CONSTRAINTS;
DROP TABLE g_enrollments CASCADE CONSTRAINTS;
DROP TABLE classes CASCADE CONSTRAINTS;
DROP TABLE course_credit CASCADE CONSTRAINTS;
DROP TABLE courses CASCADE CONSTRAINTS;
DROP TABLE students CASCADE CONSTRAINTS;
WHENEVER SQLERROR EXIT SQL.SQLCODE

CREATE TABLE students (
    B# CHAR(9) PRIMARY KEY CHECK (B# LIKE 'B%'),
    first_name VARCHAR2(15) NOT NULL,
    last_name VARCHAR2(15) NOT NULL,
    st_level VARCHAR2(10) CHECK (st_level IN ('freshman', 'sophomore', 'junior', 'senior', 'master', 'PhD')), 
    gpa NUMBER(3,2) CHECK (gpa BETWEEN 0 AND 4.0),
    email VARCHAR2(20) UNIQUE,
    bdate DATE
);

CREATE TABLE courses (
    dept_code VARCHAR2(4),
    course# NUMBER(3) CHECK (course# BETWEEN 100 AND 799),
    title VARCHAR2(20) NOT NULL,
    PRIMARY KEY (dept_code, course#)
);

CREATE TABLE course_credit (
    course# NUMBER(3) PRIMARY KEY CHECK (course# BETWEEN 100 AND 799),
    credits NUMBER(1) CHECK (credits IN (3, 4)), CHECK ((course# < 500 AND credits = 4) OR (course# >= 500 AND credits = 3))
);

CREATE TABLE classes (
    classid CHAR(5) PRIMARY KEY CHECK (classid LIKE 'c%'),
    dept_code VARCHAR2(4) NOT NULL,
    course# NUMBER(3) NOT NULL,
    sect# NUMBER(2),
    year NUMBER(4),
    semester VARCHAR2(8) CHECK (semester IN ('Spring', 'Fall', 'Summer 1', 'Summer 2', 'Winter')), 
    limit NUMBER(3),
    class_size NUMBER(3),
    room VARCHAR2(10), 
    FOREIGN KEY (dept_code, course#) REFERENCES courses ON DELETE CASCADE, 
    UNIQUE (dept_code, course#, sect#, year, semester),
    CHECK (class_size <= limit),
    CHECK ((class_size >= 6 AND course# >= 500) OR class_size >= 10)
);

CREATE TABLE score_grade (
    score NUMBER(4, 2) PRIMARY KEY,
    lgrade VARCHAR2(2) CHECK (lgrade IN ('A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-','D', 'F', 'I')));

CREATE TABLE g_enrollments (
    g_B# CHAR(9) REFERENCES students,
    classid CHAR(5) REFERENCES classes, 
    score NUMBER(4, 2) REFERENCES score_grade,
    PRIMARY KEY (g_B#, classid)
);

CREATE TABLE prerequisites (
    dept_code VARCHAR2(4) NOT NULL,
    course# NUMBER(3) NOT NULL,
    pre_dept_code VARCHAR2(4) NOT NULL,
    pre_course# NUMBER(3) NOT NULL,
    PRIMARY KEY (dept_code, course#, pre_dept_code, pre_course#),
    FOREIGN KEY (dept_code, course#) REFERENCES courses ON DELETE CASCADE,
    FOREIGN KEY (pre_dept_code, pre_course#) REFERENCES courses ON DELETE CASCADE
);

CREATE TABLE logs (
    log# number (4) PRIMARY KEY,
    user_name VARCHAR2(10) NOT NULL,
    op_time DATE NOT NULL,
    table_name VARCHAR2(13) NOT NULL,
    operation VARCHAR2(6) NOT NULL,
    tuple_keyvalue VARCHAR2(20)
);

INSERT INTO students VALUES ('B00000001', 'Anne', 'Broder', 'master', 3.7, 'broder@bu.edu', '17-JAN-94');
INSERT INTO students VALUES ('B00000002', 'Terry', 'Buttler', 'master', 3.0, 'buttler@bu.edu', '28-MAY-93');
INSERT INTO students VALUES ('B00000003', 'Tracy', 'Wang', 'master', 4.0, 'wang@bu.edu','06-AUG-97');
INSERT INTO students VALUES ('B00000004', 'Barbara', 'Callan', 'master', 2.5, 'callan@bu.edu', '18-OCT-95');
INSERT INTO students VALUES ('B00000005', 'Jack', 'Smith', 'master', 3.2, 'smith@bu.edu', '18-OCT-95');
INSERT INTO students VALUES ('B00000006', 'Terry', 'Zillman', 'PhD', 4.0, 'zillman@bu.edu', '15-JUN-92');
INSERT INTO students VALUES ('B00000007', 'Becky', 'Lee', 'master', 4.0, 'lee@bu.edu', '12-NOV-96');
INSERT INTO students VALUES ('B00000008', 'Tom', 'Baker', 'master', null, 'baker@bu.edu', '23-DEC-97');
INSERT INTO students VALUES ('B00000009', 'Ben', 'Liu', 'master', 3.8, 'liu@bu.edu', '18-MAR-96');
INSERT INTO students VALUES ('B00000010', 'Sata', 'Patel', 'master', 3.9, 'patel@bu.edu', '12-OCT-94');
INSERT INTO students VALUES ('B00000011', 'Art', 'Chang', 'PhD', 4.0, 'chang@bu.edu', '08-JUN-93');
INSERT INTO students VALUES ('B00000012', 'Tara', 'Ramesh', 'senior', 3.98, 'ramesh@bu.edu', '29-JUL-98');

INSERT INTO courses VALUES ('CS', 432, 'database systems');
INSERT INTO courses VALUES ('Math', 314, 'discrete math');
INSERT INTO courses VALUES ('CS', 240, 'data structure');
INSERT INTO courses VALUES ('CS', 575, 'algorithms');
INSERT INTO courses VALUES ('CS', 532, 'database systems');
INSERT INTO courses VALUES ('CS', 550, 'operating systems');
INSERT INTO courses VALUES ('CS', 536, 'machine learning');

INSERT INTO course_credit VALUES (432, 4);
INSERT INTO course_credit VALUES (314, 4);
INSERT INTO course_credit VALUES (240, 4);
INSERT INTO course_credit VALUES (536, 3);
INSERT INTO course_credit VALUES (532, 3);
INSERT INTO course_credit VALUES (550, 3);
INSERT INTO course_credit VALUES (575, 3);

-- UNIQUE (                     dept_code, course#, sect#, year, semester)
INSERT INTO classes VALUES ('c0001', 'CS', 432, 1, 2027, 'Spring', 13, 12, 'LH 005');
INSERT INTO classes VALUES ('c0002', 'Math', 314, 1, 2026, 'Fall', 13, 12, 'LH 009');
INSERT INTO classes VALUES ('c0003', 'Math', 314, 2, 2026, 'Fall', 14, 11, 'LH 009');
INSERT INTO classes VALUES ('c0004', 'CS', 432, 2, 2027, 'Spring', 13, 13, 'SW 222');
INSERT INTO classes VALUES ('c0005', 'CS', 536, 1, 2027, 'Spring', 14, 13, 'LH 003');
INSERT INTO classes VALUES ('c0006', 'CS', 532, 1, 2026, 'Spring', 10, 9, 'LH 005');
INSERT INTO classes VALUES ('c0007', 'CS', 550, 1, 2025, 'Spring', 11, 11, 'WH 155');
INSERT INTO classes VALUES ('c0008', 'CS', 240, 1, 2026, 'Fall', 20, 10, 'LH 101');
INSERT INTO classes VALUES ('c0009', 'Math', 314, 3, 2026, 'Fall', 12, 12, 'LH 009');
INSERT INTO classes VALUES ('c0010', 'CS', 575, 1, 2026, 'Fall', 15, 8, 'WH 155');
INSERT INTO classes VALUES ('c0011', 'CS', 536, 2, 2026, 'Spring', 14, 10, 'LH 003');
INSERT INTO classes VALUES ('c0012', 'CS', 550, 1, 2026, 'Fall', 14, 9, 'LH 005');

INSERT INTO score_grade VALUES (92, 'A');
INSERT INTO score_grade VALUES (79.5, 'B');
INSERT INTO score_grade VALUES (84, 'B+');
INSERT INTO score_grade VALUES (72.8, 'B-');
INSERT INTO score_grade VALUES (76, 'B');
INSERT INTO score_grade VALUES (65.35, 'C');
INSERT INTO score_grade VALUES (94, 'A');
INSERT INTO score_grade VALUES (82, 'B+');
INSERT INTO score_grade VALUES (88, 'A-');
INSERT INTO score_grade VALUES (68, 'C+');

INSERT INTO g_enrollments VALUES ('B00000001', 'c0001', 92);
INSERT INTO g_enrollments VALUES ('B00000002', 'c0002', 76);
INSERT INTO g_enrollments VALUES ('B00000003', 'c0004', 94);
INSERT INTO g_enrollments VALUES ('B00000004', 'c0004', 65.35);
INSERT INTO g_enrollments VALUES ('B00000004', 'c0005', 82);
INSERT INTO g_enrollments VALUES ('B00000005', 'c0006', 79.5);
INSERT INTO g_enrollments VALUES ('B00000006', 'c0006', 92);
INSERT INTO g_enrollments VALUES ('B00000001', 'c0002', 68);
INSERT INTO g_enrollments VALUES ('B00000003', 'c0005', null);
INSERT INTO g_enrollments VALUES ('B00000007', 'c0007', 92);
INSERT INTO g_enrollments VALUES ('B00000001', 'c0003', 76);
INSERT INTO g_enrollments VALUES ('B00000001', 'c0006', 72.8);
INSERT INTO g_enrollments VALUES ('B00000001', 'c0004', 94);
INSERT INTO g_enrollments VALUES ('B00000001', 'c0005', 76);
INSERT INTO g_enrollments VALUES ('B00000003', 'c0001', 84);
INSERT INTO g_enrollments VALUES ('B00000005', 'c0001', 76);

INSERT INTO prerequisites VALUES ('CS', 432, 'CS', 240);
INSERT INTO prerequisites VALUES ('CS', 532, 'CS', 432);
INSERT INTO prerequisites VALUES ('CS', 536, 'CS', 240);
INSERT INTO prerequisites VALUES ('CS', 550, 'CS', 240);
INSERT INTO prerequisites VALUES ('CS', 575, 'Math', 314);
INSERT INTO prerequisites VALUES ('CS', 575, 'CS', 240);
