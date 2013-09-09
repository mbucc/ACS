-- /www/doc/sql/massage.sql
--
-- Data model for massage module
--
-- audrey@arsdigita.com June 2000
--
-- massage.sql,v 3.1 2000/07/07 00:42:05 audrey Exp

-- This is a sub-module of the intranet

create sequence massage_session_seq start with 1;

create table massage_session (
       session_id	     integer not null primary key,
       facility_id	     references im_facilities not null,
       start_time	     date not null,
       end_time		     date not null,
       massage_length	     integer not null, -- in minutes
       break_interval	     integer not null, -- in massage length units
       repeat_for_n_weeks    integer
);

create table massage_appointment (
       user_id				 references users,
       session_id			 integer references massage_session,
       start_time			 date,
       date_reservation_made		 date
);

