-- /www/doc/sql/wap.sql
--
-- WAP data model 
--
-- aegrumet@arsdigita.com, Wed May 24 04:40:05 2000
--
-- wap.sql,v 3.2 2000/06/06 02:42:50 aegrumet Exp


-- We will store data about known WAP user agents, to hand off
-- incoming requests to the right place.

create sequence wap_user_agent_id_sequence start with 1;

create table wap_user_agents (
	user_agent_id		integer
				  constraint wap_user_agent_id_pk primary key
				  constraint wap_user_agent_id_nn not null,
	name			varchar(200)
				  constraint wap_user_agent_name_nn not null,
	creation_comment        varchar(4000),
	creation_date		date default sysdate,
	creation_user		constraint wap_user_agt_create_user_fk
				  references users,
        -- NULL implies it is active.
	deletion_date		date,
	deletion_user		constraint wap_user_agt_delete_user_fk
				  references users
);

-- A bunch of user-agent data

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'ALAV UP/4.0.7',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'Alcatel-BE3/1.0 UP/4.0.6c',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'AUR PALM WAPPER',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'Device V1.12',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'EricssonR320/R1A',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'fetchpage.cgi/0.53',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'Java1.1.8',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'Java1.2.2',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'm-crawler/1.0 WAP',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'Materna-WAPPreview/1.1.3',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'MC218 2.0 WAP1.1',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'Mitsu/1.1.A',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'MOT-CB/0.0.19 UP/4.0.5j',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'MOT-CB/0.0.21 UP/4.0.5m',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'Nokia-WAP-Toolkit/1.2',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'Nokia-WAP-Toolkit/1.3beta',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'Nokia7110/1.0',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'Nokia7110/1.0 ()',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'Nokia7110/1.0 (04.67)',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'Nokia7110/1.0 (04.69)',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'Nokia7110/1.0 (04.70)',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'Nokia7110/1.0 (04.71)',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'Nokia7110/1.0 (04.73)',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'Nokia7110/1.0 (04.74)',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'Nokia7110/1.0 (04.76)',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'Nokia7110/1.0 (04.77)',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'Nokia7110/1.0 (04.80)',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'Nokia7110/1.0 (30.05)',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'PLM''s WapBrowser',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'QWAPPER/1.0',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'R380 2.0 WAP1.1',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'SIE-IC35/1.0',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'SIE-P35/1.0 UP/4.1.2a',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'SIE-P35/1.0 UP/4.1.2a',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'UP.Browser/3.01-IG01',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'UP.Browser/3.01-QC31',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'UP.Browser/3.02-MC01',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'UP.Browser/3.02-SY01',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'UP.Browser/3.1-UPG1',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'UP.Browser/4.1.2a-XXXX',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'UPG1 UP/4.0.7',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'Wapalizer/1.0',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'Wapalizer/1.1',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'WapIDE-SDK/2.0; (R320s (Arial))',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'WAPJAG Virtual WAP',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'WAPJAG Virtual WAP',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'WAPman Version 1.1',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'WAPman Version 1.1 beta:Build W2000020401',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'Waptor 1.0',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'WapView 0.00',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'WapView 0.20371',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'WapView 0.28',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'WapView 0.37',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'WapView 0.46',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'WapView 0.47',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'WinWAP 2.2 WML 1.1',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'wmlb',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'YourWap/0.91',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'YourWap/1.16',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'Zetor',
       NULL,
       NULL,
       sysdate
from dual;






