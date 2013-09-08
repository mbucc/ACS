ad_page_contract {
    @author unknown    
    @cvs-id add-custom-column-2.tcl,v 3.3.2.5 2000/09/22 01:34:36 kevin Exp
} {
    domain_id:integer
    column_actual_name
    column_pretty_name
    column_type
    column_extra_sql
}

set domain [db_string domain_get "select domain from contest_domains where domain_id = :domain_id" -bind [ad_tcl_vars_to_ns_set domain_id]]

set table_name [db_string table_name_get "select entrants_table_name from contest_domains where domain_id = :domain_id" -bind [ad_tcl_vars_to_ns_set domain_id]]

if { $column_type == "boolean" } {
    set real_column_type "char(1) default 't' check ($column_actual_name in ('t', 'f'))"
} else {
    set real_column_type $column_type
}

set alter_sql "alter table $table_name add ($column_actual_name $real_column_type $column_extra_sql)"

set insert_sql "insert into contest_extra_columns (domain_id, column_pretty_name, column_actual_name, column_type, column_extra_sql)
values
(:domain_id, :column_pretty_name, :column_actual_name, :column_type, :column_extra_sql)"

set bind_vars [ad_tcl_vars_to_ns_set domain_id column_pretty_name column_actual_name column_type column_extra_sql]

if [catch { db_dml column_add $alter_sql
            db_dml column_register $insert_sql -bind $bind_vars }  errmsg] {
    # an error
    ad_return_error "Database Error" "Error while trying to customize $domain.
	
Tried the following SQL:
	    
<blockquote>
<pre>
$alter_sql
$insert_sql    
</pre>
</blockquote>	

and got back the following:
	
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>	
	
[ad_contest_admin_footer]" } else {
    # database stuff went OK

    doc_return  200 text/html "[ad_admin_header "Column Added"]

<h2>Column Added</h2>

[ad_admin_context_bar [list "index.tcl" "Contests"] [list "manage-domain.tcl?[export_url_vars domain_id]" "Manage Contest"] "Customize"]

<hr>

The following action has been taken:

<ul>

<li>a column called \"$column_actual_name\" has been added to the
table $table_name in the database.  The sql was
<P>
<code>
<blockquote>
$alter_sql
</blockquote>
</code>

<p>

<li>a row has been added to the SQL table contest_extra_columns
reflecting that 

<ul>

<li>this column has the pretty name (for user interface) of \"$column_pretty_name\"

</ul>
</ul>

[ad_contest_admin_footer]
"
}
