-- Wrapper script, using files in the same directory.
SET SERVEROUTPUT ON SIZE UNLIMITED
SET DEFINE OFF

@@schema.sql
@@school_pkg.sql
@@school_pkg_body.sql
@@trg_enroll.sql

SPOOL results.txt
@@test_enroll.sql
SPOOL OFF

PROMPT All objects loaded.