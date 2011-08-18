--
-- glassroom-nuke.sql -- remove all of the db objects for glassroom

drop sequence glassroom_host_id_sequence;
drop sequence glassroom_cert_id_sequence;
drop sequence glassroom_module_id_sequence;
drop sequence glassroom_logbook_entry_id_seq;
drop sequence glassroom_release_id_sequence;
drop table glassroom_info;
drop table glassroom_hosts;
drop table glassroom_certificates;
drop table glassroom_releases;
drop table glassroom_modules;
drop table glassroom_logbook;
drop table glassroom_procedures;
drop table glassroom_domains;
drop table glassroom_info;
drop table glassroom_services;
delete from general_comments where on_which_table='glassroom_logbook';
commit;
