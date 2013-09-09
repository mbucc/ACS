--
-- /packages/acs-kernel/sql/security-create.sql
--
-- @author Richard Li (richardl@arsdigita.com)
--
-- @creation-date 2000/02/02
-- @cvs-id security-create.sql,v 1.1.2.1 2001/01/09 20:51:40 khy Exp

create table secret_tokens (
    token_id                    integer
                                constraint secret_tokens_token_id_pk primary key,
    token                       char(40),
    timestamp			date
);

create sequence sec_security_token_id_seq cache 100;