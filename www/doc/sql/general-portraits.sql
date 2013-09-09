-- Table for attaching portraits to anything
-- this is used to store user uploaded portraits, portraits of pets, and other
--  system pictures. The tables here contain all the columns common to portraits
--  to allow us to remove clobs and the other many columns from original tables 

-- @author minhngo@cory.eecs.berkeley.edu
-- @creation-date 8/15/2000
-- @cvs-id general-portraits.sql,v 1.1.2.1 2000/08/27 19:58:02 mbryzek Exp

-- We can attach multiple portraits to any other row in the data
-- model. However, each row in the data model can only have one primary
-- portrait. The primary portrait is used, for example, to decide which
-- picture of a user to display on the /shared/community-member page

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
