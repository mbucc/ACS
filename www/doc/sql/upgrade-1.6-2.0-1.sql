-- upgrade from ACS 1.6 to 2.0 

-- columns needed for the registration finite state machine

alter table users add (
   approved_date         date,
   approving_note        varchar(4000),
   deleted_date          date,
   deleting_user         integer references users(user_id),
   deleting_note         varchar(4000),
   banned_date           date,
   rejected_date         date,
   rejecting_user        integer references users(user_id),
   rejecting_note        varchar(4000),
   email_verified_date   date,
   user_state            varchar(100) check(user_state in ('need_email_verification_and_admin_approv', 'need_admin_approv', 'need_email_verification', 'rejected', 'authorized', 'banned', 'deleted')));

create index users_user_state on users (user_state);

-- seed the finite state machine 

update users set user_state = 'banned' where banned_p = 't';
update users set user_state = 'deleted' where deleted_p = 't' and user_state is null;
update users set user_state = 'need_admin_approv' where approved_p = 'f' and user_state is null;
update users set user_state = 'authorized' where user_state is null;

commit;

-- these columns in the user table are now obsolete

alter table users drop column approved_p;
alter table users drop column deleted_p;
alter table users drop column banned_p;
	
-- base views that change
create or replace view users_alertable
as
select * 
 from users 
 where (on_vacation_until is null or 
        on_vacation_until < sysdate)
 and user_state = 'authorized'
 and (email_bouncing_p is null or email_bouncing_p = 'f');

create or replace view users_active
as
select * 
 from users 
 where user_state = 'authorized';

create or replace view users_spammable
as
select u.* 
 from users u, users_preferences up
 where u.user_id = up.user_id(+)
 and (on_vacation_until is null or 
      on_vacation_until < sysdate)
 and user_state = 'authorized'
 and (email_bouncing_p is null or email_bouncing_p = 'f')
 and (dont_spam_me_p is null or dont_spam_me_p = 'f');




