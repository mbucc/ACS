-- /www/doc/sql/upgrade-3.4-3.4.1.sql
--
-- Script to upgrade an ACS 3.4.1 database to ACS 3.4.2
-- 
-- upgrade-3.4.1-3.4.2.sql,v 1.1.2.14 2000/10/12 06:01:00 kevin Exp


-- BEGIN GENERAL PORTAITS --
create sequence general_portraits_id_seq start with 1;
create table general_portraits (
        portrait_id             integer 
                                constraint gp_portrait_id_pk primary key,
        on_which_table          varchar(50) not null,
        on_what_id              integer not null,
        upload_user_id          not null 
                                constraint gp_upoad_user_id_fk references users(user_id), 
        -- portrait
        portrait                blob,
        portrait_upload_date    date default sysdate,
        portrait_comment        varchar(4000),
        -- file name including extension but not path
        portrait_client_file_name       varchar(500),
        portrait_file_type              varchar(100),   -- this is a MIME type (e.g., image/jpeg)
        portrait_file_extension         varchar(50),    -- e.g., "jpg"
        portrait_original_width         integer,
        portrait_original_height        integer,
        -- if our server is smart enough (e.g., has ImageMagick loaded)
        -- we'll try to stuff the thumbnail column with something smaller
        portrait_thumbnail              blob,
        portrait_thumbnail_width        integer,
        portrait_thumbnail_height       integer,
        -- primary portrait, have one primary portrait and multiple secondary portraits
        portrait_primary_p              char(1) not null
                                        constraint gp_portrait_primary_p_ck
                                        check (portrait_primary_p in ('t', 'f')),
        -- portrait approval status
        approved_p               char(1) default 't'
                                 constraint gp_approved_p_ck
                                 check (approved_p in ('t', 'f'))
);

-- trigger to ensure only one primary portrait. We need this separate trigger
-- because it enforces a check constraint against multiple rows in the table
CREATE OR REPLACE trigger gp_portrait_primary_tr
BEFORE insert on general_portraits
FOR EACH ROW
WHEN (new.portrait_primary_p = 't')
DECLARE
   v_count_primary number;
   pragma autonomous_transaction;
BEGIN
   SELECT count(gp.portrait_id) INTO v_count_primary
     FROM general_portraits gp
    WHERE gp.on_what_id = :new.on_what_id
      AND gp.on_which_table = :new.on_which_table
      AND gp.portrait_primary_p = 't';
   IF v_count_primary >= 1 THEN
      RAISE_APPLICATION_ERROR (-20000, 'Multiple primary portrait');
   END IF;
END;
/
show errors;

-- END GENERAL PORTAITS --



-- BEGIN GENERAL PL/SQL FUNCTIONS/PROCEDURES --

-- A procedure that selects from all views, telling you which ones are not in a good state
-- You should "SET SERVEROUTPUT ON" in your sql plus session to see the output
-- No output means we didn't run into any problems
-- mbryzek, 8/26/2000

create or replace procedure ad_verify_views_by_select 
IS
  v_view_name   varchar(50);
  v_sql		varchar(4000);  -- for dynamic sql

  cursor c_user_views IS 
    select view_name from user_views;

BEGIN

	open c_user_views;

	LOOP
	    	fetch c_user_views into v_view_name;
	    	exit when c_user_views%NOTFOUND;

		v_sql := 'select count(*) from ' || v_view_name;

		BEGIN
			EXECUTE IMMEDIATE v_sql;
			EXCEPTION WHEN OTHERS THEN
				dbms_output.put_line(v_view_name || ' fails select * test');
		END;
	END LOOP;
END;
/
show errors;



-- procedure that drops the specified column from the specified table
-- iff the column exists.
-- mbryzek, 8/27/2000
create or replace procedure ad_drop_column ( p_table_name IN varchar, p_column_name IN varchar ) 
IS
	v_exists_p	number;
BEGIN
	select decode(count(*),0,0,1) into v_exists_p
          from user_tab_columns
         where TABLE_NAME = upper(p_table_name)
           and COLUMN_NAME = upper(p_column_name);

	IF v_exists_p = 1 THEN 
		EXECUTE IMMEDIATE 'alter table ' || p_table_name || ' drop column ' || p_column_name;
 	END IF;
END;
/
show errors;

-- END GENERAL PL/SQL FUNCTIONS/PROCEDURES --


-- BEGIN MIGRATE PORTRAIT INFORMATION FROM USERS TO GENERAL_PORTRAITS TABLE --
-- move the portrait info from users table to general portrait
begin 

  -- first copy all the portrait information from the users table
  -- to the general_portraits table

  insert into general_portraits (
     portrait_id, on_which_table, on_what_id,
     upload_user_id, 
     portrait, portrait_upload_date, portrait_comment,
     portrait_client_file_name, portrait_file_type, 
     portrait_file_extension, portrait_original_width,
     portrait_original_height, portrait_thumbnail,
     portrait_thumbnail_width, portrait_thumbnail_height,
     portrait_primary_p, approved_p)
   select general_portraits_id_seq.nextval, 'USERS', user_id,
           user_id,
           portrait, portrait_upload_date, portrait_comment,
           portrait_client_file_name, portrait_file_type,
           portrait_file_extension, portrait_original_width,
           portrait_original_height, portrait_thumbnail,
           portrait_thumbnail_width, portrait_thumbnail_height,
           't', 't' from users where portrait is not null;

   -- use pl/sql here since we only want to drop the columns if the above
   -- block successfully executed. Note we do this column by column to make 
   -- sure we only drop columns that do indeed exist.
   ad_drop_column('USERS','PORTRAIT');
   ad_drop_column('USERS','PORTRAIT_UPLOAD_DATE');
   ad_drop_column('USERS','PORTRAIT_COMMENT');
   ad_drop_column('USERS','PORTRAIT_FILE_TYPE');
   ad_drop_column('USERS','PORTRAIT_FILE_EXTENSION');
   ad_drop_column('USERS','PORTRAIT_CLIENT_FILE_NAME');
   ad_drop_column('USERS','PORTRAIT_ORIGINAL_HEIGHT');
   ad_drop_column('USERS','PORTRAIT_ORIGINAL_WIDTH');
   ad_drop_column('USERS','PORTRAIT_THUMBNAIL');
   ad_drop_column('USERS','PORTRAIT_THUMBNAIL_WIDTH');
   ad_drop_column('USERS','PORTRAIT_THUMBNAIL_HEIGHT');

end;
/
show errors;

-- END MIGRATE PORTRAIT INFORMATION FROM USERS TO GENERAL_PORTRAITS TABLE --



-- RECREATE USERS VIEWS WITHOUT THE PORTAIT COLUMN --
-- we could join to get the portrait column, but this is slow and the users views
-- are used quite often

create or replace view users_alertable
as
select u.* 
 from users u
 where (u.on_vacation_until is null or 
        u.on_vacation_until < sysdate)
 and u.user_state = 'authorized'
 and (u.email_bouncing_p is null or u.email_bouncing_p = 'f')
 and not exists (select 1 
                   from user_vacations v
                  where v.user_id = u.user_id
                    and sysdate between v.start_date and v.end_date);



--- users who are not deleted or banned

create or replace view users_active
as
select * 
 from users 
 where user_state = 'authorized';
  
-- users who've signed up in the last 30 days
-- useful for moderators since new users tend to 
-- be the ones who cause trouble

create or replace view users_new
as
select * 
 from users 
 where registration_date > (sysdate - 30);

create or replace view users_spammable
as
select u.*, up.email_type 
 from users u, users_preferences up
 where u.user_id = up.user_id(+)
 and user_state = 'authorized'
 and (email_bouncing_p is null or email_bouncing_p = 'f')
 and (dont_spam_me_p is null or dont_spam_me_p = 'f');


-- we have to use dynamic sql here to ensure that the table exists. If it does,
-- we create the view. Otherwise, we have nothing to worry about.
DECLARE
  v_exists_p 	number;
BEGIN
  -- Check first table in the view. 
  select decode(count(*),0,0,1) into v_exists_p
    from user_tables
   where table_name='EC_CUSTOMER_SERV_INTERACTIONS';

  IF v_exists_p = 1 THEN
	-- First table exists. Check second table
	select decode(count(*),0,0,1) into v_exists_p
	  from user_tables
   	 where table_name='EC_GIFT_CERTIFICATES_ISSUED';

  	IF v_exists_p = 1 THEN
		-- both tables exist. Create the view
		EXECUTE IMMEDIATE 'create or replace view ec_customer_service_reps
                                   as
                                   select * from users 
                                   where user_id in (select customer_service_rep from ec_customer_serv_interactions)
                                      or user_id in (select issued_by from ec_gift_certificates_issued)';
	END IF;
  END IF;
END;
/
show errors;

create or replace view im_employees_active as
select u.*, 
       info.JOB_TITLE,
       info.JOB_DESCRIPTION,
       info.TEAM_LEADER_P,
       info.PROJECT_LEAD_P,
       info.PERCENTAGE,
       info.SUPERVISOR_ID,
       info.GROUP_MANAGES,
       info.CURRENT_INFORMATION,
       info.SS_NUMBER,
       info.SALARY,
       info.SALARY_PERIOD,
       info.DEPENDANT_P,
       info.ONLY_JOB_P,
       info.MARRIED_P,
       info.DEPENDANTS,
       info.HEAD_OF_HOUSEHOLD_P,
       info.BIRTHDATE,
       info.SKILLS,
       info.FIRST_EXPERIENCE,
       info.YEARS_EXPERIENCE,
       info.EDUCATIONAL_HISTORY,
       info.LAST_DEGREE_COMPLETED,
       info.RESUME,
       info.RESUME_HTML_P,
       info.START_DATE,
       info.RECEIVED_OFFER_LETTER_P,
       info.RETURNED_OFFER_LETTER_P,
       info.SIGNED_CONFIDENTIALITY_P,
       info.MOST_RECENT_REVIEW,
       info.MOST_RECENT_REVIEW_IN_FOLDER_P,
       info.FEATURED_EMPLOYEE_APPROVED_P,
       info.FEATURED_EMPLOYEE_BLURB_HTML_P,
       info.FEATURED_EMPLOYEE_BLURB,
       info.REFERRED_BY
from users_active u, 
     (select * 
        from im_employee_info info 
       where sysdate>info.start_date
         and sysdate > info.start_date
         and sysdate <= nvl(info.termination_date, sysdate)
         and ad_group_member_p(info.user_id, (select group_id from user_groups where short_name='employee')) = 't'
     ) info
where info.user_id=u.user_id;

-- BEGIN SITE WIDE SEARCH --

-- allow larger sections for queries
alter table query_strings modify (subsection varchar2(4000));

-- END SITE WIDE SEARCH --


