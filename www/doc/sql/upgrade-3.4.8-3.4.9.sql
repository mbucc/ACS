-- /www/doc/sql/upgrade-3.4.8-3.4.9.sql
--
-- Script to upgrade an ACS 3.4.8 database to ACS 3.4.9
-- 
-- upgrade-3.4.8-3.4.9.sql,v 1.1.2.2 2000/11/20 23:55:21 ron Exp

-- added one column to adv_groups to correctly support sequential rotation

alter table adv_group_map add rotation_order integer;

