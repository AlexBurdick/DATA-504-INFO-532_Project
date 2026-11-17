# DATA-504-INFO-532_Project
Repository for final project

# CS 432 / [Course #] — Database Systems Project

Oracle PL/SQL implementation of a university course-registration system:
schema, packages, procedures, and triggers for enrolling/dropping graduate
students, finding prerequisites, and auditing changes.

**Author:** Alex Burdick (aburdick3@gmail.com)
**Course:** DATA-504/INFO-532, Fall 2026
**Oracle version tested:** Oracle Database 19c Enterprise Edition 19.14.0.0.0
**Client:** SQL*Plus

---

## 1. What this project does

Implements the following operations against the `students`, `courses`,
`classes`, `g_enrollments`, `prerequisites`, `score_grade`, and `logs`
tables:

| # | Operation | Where |
|---|---|---|
| 1 | Create the sequence used for log primary keys | `log_seq.sql` (or top of `package.sql`) |
| 2 | Enroll a graduate student into a class (with 8 validations) | `school_pkg.enroll_graduate` |
| 3 | Drop a graduate student from a class (with 6 validations) | `registration.drop_student` |
| 4 | Find all direct and indirect prerequisites of a course | `school_pkg.get_all_prerequisites` |
| 5 | Delete a student and cascade their enrollments | `school_pkg.delete_student` |
| 6 | Show every tuple of every table (demo/debug) | `student_registration.show_all` |
| 7 | Show all students enrolled in a given class | `student_registration.show_class_students` |
| 8 | Automatic class-size maintenance and audit logging | triggers in `trg_add_drop.sql` |

All data-changing operations are validated and either succeed or raise a
numbered `ORA-20xxx` application error with a human-readable message.

---

## 2. Repository layout
.
├── README.md <- this file
├── schema.sql <- DDL + seed data for all tables
├── log_seq.sql <- CREATE SEQUENCE log_seq
├── school_pkg.sql <- package SPEC (school_pkg)
├── school_pkg_body.sql <- package BODY (school_pkg)
├── package.sql <- package registration + sequence + triggers
├── trg_add_drop.sql <- triggers for enroll/drop/delete + logging
├── projectquery2.sql <- student_registration package (show_* procs)
├── projectquery3.sql <- show_class_students procedure
├── projectquery7.sql <- delete_student procedure (+ optional trigger)
├── test_enroll.sql <- Q4/Q5 test block (prereqs + enroll + triggers)
├── test_drop.sql <- drop_student tests [if present]
├── test_delete.sql <- delete_student tests [if present]
└── results/ <- spooled test output [if you keep them]
├── test_enroll.txt
├── test_drop.txt
└── test_delete.txt

### File responsibilities

| File | What it contains | Depends on |
|---|---|---|
| `schema.sql` | `DROP TABLE` + `CREATE TABLE` + `INSERT` seed data for all 9 tables | nothing |
| `log_seq.sql` | `CREATE SEQUENCE log_seq START WITH 1000 INCREMENT BY 1` | nothing |
| `school_pkg.sql` | Spec for `get_all_prerequisites`, `enroll_graduate`, `delete_student` | tables |
| `school_pkg_body.sql` | Implementation of `school_pkg` | `school_pkg.sql` |
| `package.sql` | `registration` package (`drop_student`) + sequence + Task 8 triggers | `schema.sql`, sequence |
| `trg_add_drop.sql` | `trg_student_delete`, `trg_g_enroll_insert`, `trg_g_enroll_delete` | `schema.sql`, sequence |
| `projectquery2.sql` | `student_registration` package (eight `show_*` + `show_all`) | `schema.sql` |
| `projectquery3.sql` | `show_class_students` procedure | `schema.sql` |
| `projectquery7.sql` | `delete_student` procedure | `schema.sql`, sequence (for its trigger) |
| `test_*.sql` | Anonymous PL/SQL blocks that exercise each feature | all of the above |

> **Note:** `delete_student` exists in both `school_pkg` and `projectquery7.sql`.
> `projectquery7.sql` is the standalone version for that question; `school_pkg`
> is the integrated version. Load **one**, or make sure the two don't both
> define the same trigger (see §5).

---

## 3. Prerequisites

- Oracle Database 11g R2 or later (tested on **19c**). The recursive `WITH`
  clause used in `get_all_prerequisites` requires 11g R2+.
- A schema user with `CREATE TABLE`, `CREATE SEQUENCE`, `CREATE PROCEDURE`,
  `CREATE PACKAGE`, and `CREATE TRIGGER` privileges.
- SQL*Plus (or SQL Developer / DBeaver). The scripts use SQL*Plus directives
  (`WHENEVER SQLERROR`, `SET DEFINE OFF`, `SHOW ERRORS`, `PROMPT`, `SPOOL`).

```sql
-- connect as your schema user, e.g.:
sqlplus myuser/mypassword@localhost:1521/XEPDB1

---

## Setup and Run

**Prerequisites:** Oracle Database 11g R2+ (tested on 19c), SQL*Plus, and a
schema user with `CREATE TABLE`, `CREATE SEQUENCE`, `CREATE PROCEDURE`,
`CREATE PACKAGE`, `CREATE TRIGGER`.

**Load order** (strict — tables before sequence, sequence before triggers,
spec before body):

```sql
-- connect as your schema user
sqlplus myuser/mypassword@localhost:1521/XEPDB1

-- 1. tables + seed data
@schema.sql

-- 2. log sequence (also the first statement in package.sql)
@log_seq.sql

-- 3. school_pkg spec, then body
@school_pkg.sql
SHOW ERRORS PACKAGE school_pkg;
@school_pkg_body.sql
SHOW ERRORS PACKAGE BODY school_pkg;

-- 4. registration package + Task 8 triggers
@package.sql

-- 5. show_* package and procedures
@projectquery2.sql
@projectquery3.sql
@projectquery7.sql

-- 6. enrollment / drop / delete triggers
@trg_add_drop.sql

-- 7. one-time cleanup: remove duplicate class-size triggers if present
DROP TRIGGER trg_enroll_inc_class_size;
DROP TRIGGER trg_enroll_dec_class_size;
```

**Verify it loaded cleanly:**

```sql
-- every package/spec/body/trigger should say VALID / ENABLED
SELECT object_name, object_type, status
  FROM user_objects
 WHERE object_name IN ('SCHOOL_PKG','REGISTRATION','STUDENT_REGISTRATION')
    OR object_type = 'TRIGGER'
 ORDER BY object_type, object_name;

-- exactly three triggers on students/g_enrollments
SELECT trigger_name, table_name, triggering_event, status
  FROM user_triggers
 WHERE table_name IN ('STUDENTS','G_ENROLLMENTS')
 ORDER BY table_name, triggering_event;
```

**Run the tests:**

```sql
SET SERVEROUTPUT ON SIZE UNLIMITED
@test_enroll.sql
```

`SET SERVEROUTPUT ON` is required — without it, `DBMS_OUTPUT.PUT_LINE`
prints to a buffer you can't see. See §6 for how the "current semester"
check interacts with the test date, and §7 for resetting state between runs.