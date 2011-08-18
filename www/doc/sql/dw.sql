--
-- queries.sql 
--
-- defined by philg@mit.edu on December 25, 1998
--
-- tables for storing user queries
--

create sequence query_sequence;

create table queries (
	query_id	integer primary key,
	query_name	varchar(100) not null,
	query_owner	not null references users,
	definition_time	date not null,
	-- if this is non-null, we just forget about all the query_columns
	-- stuff; the user has hand-edited the SQL
	query_sql	varchar(4000)
);

-- we store old hand-edited SQL in here 

create table queries_audit (
	query_id	integer not null,
	audit_time	date not null,
	query_sql	varchar(4000)
);

create or replace trigger queries_audit_sql
before update on queries
for each row
when (old.query_sql is not null and (new.query_sql is null or old.query_sql <> new.query_sql))
begin
  insert into queries_audit (query_id, audit_time, query_sql)
  values
  (:old.query_id, sysdate, :old.query_sql);
end;
/
show errors




-- this specifies the columns we we will be using in a query and
-- what to do with each one, e.g., "select_and_group_by" or
-- "select_and_aggregate"

-- "restrict_by" is tricky; value1 contains the restriction value, e.g., '40'
-- or 'MA' and value2 contains the SQL comparion operator, e.g., "=" or ">"

create table query_columns (
	query_id	not null references queries,
	column_name	varchar(30),
	pretty_name	varchar(50),
	what_to_do	varchar(30),
	-- meaning depends on value of what_to_do
	value1		varchar(4000),
	value2		varchar(4000)
);

create index query_columns_idx on query_columns(query_id);

