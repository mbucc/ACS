ad_page_contract {

    A set of DB API tests.

    @creation-date 08 July 2000
    @author Bryan Quinn [bquinn@arsdigita.com]
    @author yon [yon@arsdigita.com]
    @cvs-id index.tcl,v 1.1.2.3 2000/09/22 01:34:10 kevin Exp
} {}



proc manual_dml { } {
if [catch {
    db_with_handle db {
	ns_ora dml $db "insert into foo20 (id, str) values (:id, :str) -bind $bind_vars"
	
    }
} errmsg] {
    ns_write $errmsg
}
}

ad_proc -public one_doc_entry {description requires proc_name expected_results} {
    set html ""
    append html "<h3>Testing <a href=\"/api-doc/proc-view?proc=[ns_urlencode $proc_name]\">$proc_name</a>
</h3><p><blockquote>$description</blockquote><p> 
"
    regsub {db\_} $proc_name {dbtest_} proc_name
    set real_proc $proc_name
    append html "
 <a href=\"/api-doc/proc-view?proc=[ns_urlencode $proc_name]\">VIEW TEST CODE</a><p>"
    if { [llength $requires] >0 } {
	append html "This test requires <ul>"
	foreach req $requires {
	    set proc_name $req
	    append html "<li> <a href=\"/api-doc/proc-view?proc=[ns_urlencode $proc_name]\">$req</a><p>"
	}
	append html "</ul><p>"
    }
    append html "Test results: "
    set result [eval $real_proc]
    if ![string compare $result $expected_results] {
	append html "<font color=green>SUCCESS: Results are correct.</font><blockquote><pre>$result</pre></blockquote>"
    } else {
	append html "<font color=red>FAILURE: Results are incorrect.</font><blockquote><pre>$result</pre></blockquote>Results should be:<br> <blockquote><pre>$expected_results</pre></blockquote>"
    }
append html "
</pre></blockquote>
<font color=red>End $real_proc.</font>
<hr>
"
    return $html
}

ad_proc -public dbtest_prepare_table {} {
    catch {
	db_dml test_drop "DROP TABLE dbtest_table"
    }
    db_dml test_ddl "CREATE TABLE dbtest_table (id INTEGER, str VARCHAR(4000))"
    set str "foo"
    for {set id 0} {$id < 5} {incr id} {
	db_dml test_insert {
	    insert into dbtest_table (id, str) values (:id, :str)
	}
    }
}

ad_proc -public dbtest_foreach {} {
    
    set result ""
    dbtest_prepare_table
    set rows [list "foo" "bar" "baz" "zorp"]
    foreach str $rows {
	db_dml test_insert {
	    insert into dbtest_table (id, str) values (13, :str)
	}
    }
    set id 13
    set bind_vars [ad_tcl_vars_to_ns_set id]
    set sql_qry "select id, str from dbtest_table where id = :id"
    db_foreach test_foreach $sql_qry  -bind $bind_vars {
	global f
	append result "Test: id: $id, str: $str\n"
    } if_no_rows {
	append result "No data"
    }
    db_dml "test_delete" "delete from dbtest_table"
    # now do an if_no_rows
    db_foreach test_foreach $sql_qry  -bind $bind_vars {
	append result "Test: id: $id, str: $str\n"
    } if_no_rows {
	append result "No data"
    }
    return $result
}

ad_proc -public dbtest_0or1row {} {
    set result ""
    dbtest_prepare_table
    set id 1
    set id 1
    set bind_vars [ad_tcl_vars_to_ns_set id]
    set sql_qry "select id, str from dbtest_table where id = :id"
    if [db_1row db1row {select id, str from dbtest_table where id = :id} -bind $bind_vars] {
	    append result "Test: id: $id, str: $str"
    } else {
	append result "No rows were returned."
    }
    return $result
}



ad_proc -public dbtest_1row {} {
    set result ""
    dbtest_prepare_table
    set id 1
    set bind_vars [ad_tcl_vars_to_ns_set id]
    set sql_qry "select id, str from dbtest_table where id = :id"
    if [catch {
	db_1row db1row {select id, str from dbtest_table where id = :id} -bind $bind_vars
    } errmsg ] {
	append result "Error: $errmsg"
	return $result
    } else {
	append result "Test: id: $id, str: $str"
    }
    return $result
}

ad_proc -public dbtest_string {} {
    set result ""
    set sql_qry  "select 'foo' as foo from dual where 1 = :var"
    set bind_vars [ns_set create]
    ns_set put $bind_vars var 1
    set foo [db_string "foo" $sql_qry -bind $bind_vars]
    append result "$foo\n" 
    # should be the date.

    ns_set update $bind_vars var 2
    set foo [db_string "foo" $sql_qry -default "no string" -bind $bind_vars]
    append result "$foo\n" 
    # should be "no date"

    if [catch {
	set foo [db_string "date" $sql_qry -bind $bind_vars]
    } errmsg] {
	append result $errmsg
	# should be "Selection did not return a value, and no default was provided"
    } 
    return $result
}

ad_proc -public dbtest_prepare_lob_table {} {
    catch {
	db_dml test_lob_drop "drop table dbtest_lob_table"
    }
    db_dml test_lob_ddl "create table dbtest_lob_table (id integer, str varchar(4000), the_clob clob, the_blob blob)"
}

ad_proc -public dbtest_dml {} {
    set result ""
    set id 1

    dbtest_prepare_table
    set str "1st test string"

    set bind_vars [ad_tcl_vars_to_ns_set id str]

    db_dml dml_test_1 {
	delete from dbtest_table where id = :id
    } -bind $bind_vars

    append result [db_string dml_test_1_check {
	select '<li>' || str || '</li>' from dbtest_table where id = :id
    } -default "<li>no rows selected</li>" -bind $bind_vars]

    db_dml dml_test_2 "
	insert into dbtest_table ([join [ad_ns_set_keys $bind_vars] ", "])
        values ([join [ad_ns_set_keys -colon $bind_vars] ", "])
    " -bind $bind_vars

    append result [db_string dml_test_2_check {
	select '<li>' || str || '</li>' from dbtest_table where id = :id
    } -default "<li>no rows selected</li>" -bind $bind_vars]

    set str "2nd test string"
    ad_tcl_vars_to_ns_set -set_id $bind_vars str

    db_dml dml_test_3 {
	update dbtest_table
	   set str = :str
	 where id = :id
    } -bind $bind_vars

    append result [db_string dml_test_3_check {
	select '<li>' || str || '</li>' from dbtest_table where id = :id
    } -default "<li>no rows selected</li>" -bind $bind_vars]

    ns_set free $bind_vars

    dbtest_prepare_lob_table

    db_dml dml_lob_test_1 {
	insert into dbtest_lob_table (id, the_clob)
	values (1, empty_clob())
	returning the_clob into :1
    } -clob_files [list "/webroot/web/acs-staging/www/acs-examples/dbtest/sample-clob.txt"]

    append result [db_string dml_lob_test_1_check {
	select '<li>' || count(1) || ' clob</li>' from dbtest_lob_table where id = 1 and the_clob is not null
    } -default "<li>no rows selected</li>"]

    set foo "blah, blah"
    db_dml dml_lob_test_1 {
	insert into dbtest_lob_table (id, str, the_blob)
	values (2, :foo, empty_blob())
	returning the_blob into :1
    } -blob_files [list "/webroot/web/acs-staging/www/acs-examples/dbtest/sample-blob.bin"]

    db_dml dml_lob_test_3 "insert into dbtest_lob_table (id, the_clob) values (6, empty_clob()) 
	returning the_clob into :1" -clobs {""}

    append result [db_string dml_lob_test_1_check {
	select '<li>' || count(1) || ' blob</li>' from dbtest_lob_table where id = 2 and the_blob is not null
    } -default "<li>no rows selected</li>"]

    return $result
}

set html ""

append html "<html><head><title>DB_API Tests</title></head><body bgcolor=white fgcolor=black>"
append html "<h2> Prototype DB_API Testing Page</h2><hr>
This page runs a set of sample db queries checks the results against known benchmarks.<hr>"
global foo
set foo "bar"
append html [one_doc_entry "" [list "dbtest_prepare_table"] db_foreach "Test: id: 13, str: foo\nTest: id: 13, str: bar\nTest: id: 13, str: baz\nTest: id: 13, str: zorp\nNo data"]

append html [one_doc_entry "" [list "dbtest_prepare_table"]  db_1row "Test: id: 1, str: foo"]

append html [one_doc_entry "" [list] db_string "foo\nno string\nSelection did not return a value, and no default was provided"]

append html [one_doc_entry "" [list dbtest_prepare_table dbtest_prepare_lob_table] db_dml "<li>no rows selected</li><li>1st test string</li><li>2nd test string</li><li>1 clob</li><li>1 blob</li>"]

append html "
<address>bquinn@arsdigita.com<br>
</body> </html>
"

set selection [ns_set create]

db_1row stm_name {
    select sysdate as mydate, sysdate - 1 as mydate2 from dual
} -column_set selection

append html "[ns_set get $selection mydate] : [ns_set get $selection mydate2]"

set str "cat"
set bind_vars [ad_tcl_vars_to_ns_set str]
db_1row stm_name {
    select id from foo34 where str = :str
} -bind $bind_vars

append html "THE CAT IN THE $id"


db_release_unused_handles
doc_return 200 "text/html" $html