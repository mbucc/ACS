-- /www/doc/sql/upgrade-3.4.2-3.4.3.sql
--
-- Script to upgrade an ACS 3.4.2 database to ACS 3.4.3
-- 
-- upgrade-3.4.2-3.4.3.sql,v 1.1.2.7 2000/10/12 06:01:00 kevin Exp


-- The last upgrade script left out these categories needed for the intranet task board
-- mbryzek@arsdigita.com, 9/3/2000

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('0',
  '',
  'f',
  category_id_sequence.nextVal,
  '15 Minutes',
  '',
  'Intranet Task Board Time Frame');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('2',
  '',
  'f',
  category_id_sequence.nextVal,
  '1 hour',
  '',
  'Intranet Task Board Time Frame');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('3',
  '',
  'f',
  category_id_sequence.nextVal,
  '1 day',
  '',
  'Intranet Task Board Time Frame');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('4',
  '',
  'f',
  category_id_sequence.nextVal,
  'Side Project',
  '',
  'Intranet Task Board Time Frame');

insert into categories
 (PROFILING_WEIGHT,
  CATEGORY_DESCRIPTION,
  ENABLED_P,
  CATEGORY_ID,
  CATEGORY,
  MAILING_LIST_INFO,
  CATEGORY_TYPE) 
values 
 ('10',
  '',
  'f',
  category_id_sequence.nextVal,
  'Full Time',
  '',
  'Intranet Task Board Time Frame');

--
-- CALENDAR
--
-- The new calendar module was not supposed to be released in 3.4.2
--
-- This set of commands should drop the calendar stuff
--

declare 
    v_count	integer
begin

    select count(*) into v_count
    from   user_tables
    where  table_name = 'CAL_CATEGORIES';

    if v_count > 0 then

        drop trigger cal_groups_insert;
        drop trigger cal_groups_add;
        drop trigger cal_groups_remove;
        drop trigger cal_user_add;
        drop trigger cal_user_remove;
        
        drop procedure cal_insert_instances;
        drop function combine_category_names;
        drop procedure insert_cal_generic_rows;
        
        drop view cal_user_write_privilege;
        drop view cal_user_read_privilege;
        drop view cal_hours;
        drop view cal_week_days;
        drop view cal_month_days;
        
        drop table cal_generic_rows;
        drop table cal_alerts;
        drop table cal_user_prefs;
        drop table cal_user_update_prefs;
        drop table cal_user_item_filter;
        
        drop table cal_db_row_map;
        drop table cal_instance_db_row_map;
        
        drop table cal_item_map;
        drop table cal_category_map;
        
        drop table cal_groups;
        drop table cal_group_types;
        
        drop table cal_repeat_items;
        drop table cal_item_instances;
        drop table cal_items;
        
        drop table cal_categories;
        
        drop sequence cal_category_id_sequence;
        drop sequence cal_item_id_sequence;
        drop sequence cal_instance_id_sequence;

    end if;

end;

--
-- PETS
--
-- Pets module is not supposed to be in 3.4
--

declare
    v_count	integer
begin
    select count(*) into v_count
    from   user_tables
    where  table_name = 'USER_PETS';

    if v_count > 0 then

        drop sequence user_pets_id_seq;
        drop sequence pet_category_id_seq;
        
        drop table user_pets;
        drop table pet_category;

    end if;

end;

--
-- SITE-WIDE-SEARCH	
--
-- Scoping columns in static_pages were a mistake
--

declare
    v_count	integer
begin
    select count(*) into v_cont
    from   user_tab_columns
    where  table_name = 'STATIC_PAGES'
    and    column_name = 'SCOPE';

    if v_count > 0 then

        alter table static_pages drop constraint sp_sws_scope_check;
        alter table static_pages drop column scope;
        alter table static_pages drop column group_id;

    end if;

end;