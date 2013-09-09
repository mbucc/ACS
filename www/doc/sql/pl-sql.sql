--
-- pl-sql.sql 
-- 
-- created by philg on 11/18/98
--
-- useful pl/sql utility procedures 
--

create or replace function logical_negation(true_or_false IN varchar)
return varchar
is
BEGIN
  IF true_or_false is null THEN
    return null;
  ELSIF true_or_false = 'f' THEN
    return 't';   
  ELSE 
    return 'f';   
  END IF;
END logical_negation;
/
show errors

-- these come originally from the classified ads system

create or replace function expired_p(expiration_date in date) return varchar
is
begin
	IF expiration_date is null THEN 
            return 'f';
        ELSIF expiration_date >= sysdate THEN
            return 'f';
	ELSE
	    return 't';
	END IF;
end;
/
show errors

create or replace function days_since_posted(foo in date) return integer
is
begin
	return round(sysdate - foo);
end;
/
show errors


-- useful for ecommerce and other situations where you want to
-- know whether something happened within last N days (assumes query_date
-- is in the past)

create or replace function one_if_within_n_days (query_date IN date, n_days IN integer)
return integer
is
begin
  IF (sysdate - query_date) <= n_days THEN 
    return 1;
  ELSE
    return 0;
  END IF;
end one_if_within_n_days;
/
show errors

create or replace function pseudo_contains (indexed_stuff IN varchar, space_sep_list_untrimmed IN varchar)
return integer
IS
  space_sep_list        varchar(32000);
  upper_indexed_stuff   varchar(32000);
  -- if you call this var START you get hosed royally
  first_space           integer;
  score                 integer;
BEGIN 
  space_sep_list := upper(ltrim(rtrim(space_sep_list_untrimmed)));
  upper_indexed_stuff := upper(indexed_stuff);
  score := 0;
  IF space_sep_list is null or indexed_stuff is null THEN
    RETURN score;  
  END IF;
  LOOP
   first_space := instr(space_sep_list,' ');
   IF first_space = 0 THEN
     -- one token or maybe end of list
     IF instr(upper_indexed_stuff,space_sep_list) <> 0 THEN
        RETURN score+10;
     END IF;
     RETURN score;
   ELSE
   -- first_space <> 0
     IF instr(upper_indexed_stuff,substr(space_sep_list,1,first_space-1)) <> 0 THEN
        score := score + 10;
     END IF;
   END IF;
    space_sep_list := substr(space_sep_list,first_space+1);
  END LOOP;  
END pseudo_contains;
/
show errors




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


