--
-- glossary.sql
--
-- defined by philg@mit.edu on March 6, 1999
--
-- a system that lets a group of people collaboratively maintain
-- a glossary
--

-- we limit the definition to 4000 chars because we don't want to deal with CLOBs

create table glossary (
	term		varchar(200) primary key,
	definition	varchar(4000) not null,
	author			not null references users,
	approved_p		char(1) default 'f' check(approved_p in ('t','f')),
	creation_date		date not null,
	modification_date	date not null
);

create or replace trigger glossary_modified
before insert or update on glossary
for each row
begin
  :new.modification_date := sysdate;
end;
/
show errors

-- the same thing as GLOSSARY but without a primary key constraint on TERM

create table glossary_audit (
	term		varchar(200),
	definition	varchar(4000),
	author			integer,
	modification_date	date
);

create or replace trigger glossary_audit_sql
before update on glossary
for each row
begin
  insert into glossary_audit (term, definition, author, modification_date)
  values
  (:old.term, :old.definition, :old.author, :old.modification_date);
end;
/
show errors
