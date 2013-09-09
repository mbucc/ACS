-- /www/doc/sql/upgrade-3.4.4-3.4.5.sql
--
-- Script to upgrade an ACS 3.4.4 database to ACS 3.4.5
-- 
-- upgrade-3.4.4-3.4.5.sql,v 1.1.2.4 2000/09/22 15:43:38 kevin Exp

-- Recreate the USERS_ALERTABLE view to handle
-- out-of-office-but-still-able-to-receive-email cases

create or replace view users_alertable as
select u.* 
 from users u
 where (u.on_vacation_until is null or 
        u.on_vacation_until < sysdate)
 and u.user_state = 'authorized'
 and (u.email_bouncing_p is null or u.email_bouncing_p = 'f')
 and not exists (select 1 
                   from user_vacations v
                  where v.user_id = u.user_id
                    and sysdate between v.start_date and v.end_date
                    and receive_email_p = 'f');