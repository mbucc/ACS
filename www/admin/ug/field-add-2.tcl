# $Id: field-add-2.tcl,v 3.0 2000/02/06 03:28:35 ron Exp $
set_the_usual_form_variables

# group_type, column_name, pretty_name, column_type, column_actual_type
# column_extra, after (optional)

set db [ns_db gethandle]

set table_name [ad_user_group_helper_table_name $group_type]

set alter_sql "alter table $table_name add ($column_name $column_actual_type $column_extra)"

if { [exists_and_not_null after] } {
    set sort_key [expr $after + 1]
    set update_sql "update user_group_type_fields
set sort_key = sort_key + 1
where group_type = '$QQgroup_type'
and sort_key > $after"
} else {
    set sort_key 1
    set update_sql ""
}


set insert_sql "insert into user_group_type_fields (group_type, column_name, pretty_name, column_type, column_actual_type, column_extra, sort_key)
values
( '$QQgroup_type', '$QQcolumn_name', '$QQpretty_name','$QQcolumn_type', '$QQcolumn_actual_type', [ns_dbquotevalue $column_extra text], $sort_key)"

with_transaction $db {
    ns_db dml $db $alter_sql
    if { ![empty_string_p $update_sql] } {
	ns_db dml $db $update_sql
    }
    ns_db dml $db $insert_sql
} {
    # an error
    ad_return_error "Database Error" "Error while trying to customize $group_type.
	
Tried the following SQL:
	    
<blockquote>
<pre>
$alter_sql
$update_sql
$insert_sql    
</pre>
</blockquote>	

and got back the following:
	
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>	
	
[ad_admin_footer]"
    return
}

# database stuff went OK
ns_return 200 text/html "[ad_admin_header "Field Added"]

<h2>Field Added</h2>

to <a href=\"group-type.tcl?[export_url_vars group_type]\">the $pretty_name group type</a>

<hr>

The following action has been taken:

<ul>

<li>a column called \"$column_name\" has been added to the
table $table_name in the database.  The sql was
<P>
<code>
<blockquote>
$alter_sql
</blockquote>
</code>

<p>

<li>a row has been added to the SQL table user_group_type_fields
reflecting that 

<ul>

<li>this field has the pretty name (for user interface) of \"$pretty_name\"

</ul>
</ul>

[ad_admin_footer]
"
