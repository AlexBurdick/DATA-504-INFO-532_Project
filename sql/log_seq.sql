-- Creates a sequence to automatically generate log primary keys
-- Starts at 1000 and increments by 1 for each new log entry
CREATE SEQUENCE log_seq
START WITH 1000
INCREMENT BY 1;