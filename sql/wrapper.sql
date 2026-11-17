-- Wrapper script, using files in the same directory.
SET SERVEROUTPUT ON SIZE UNLIMITED
SET DEFINE OFF

WHENEVER SQLERROR CONTINUE
@@schema.sql
--WHENEVER SQLERROR EXIT SQL.SQLCODE

@@log_seq.sql
@@school_pkg.sql
@@school_pkg_body.sql
@@trg_add_drop.sql

SPOOL results.txt
@@test_enroll.sql
SPOOL OFF

PROMPT All objects loaded.