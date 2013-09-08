#www/admin/ug/field-add-2.tcl 

ad_page_contract {
    @cvs-id field-add-2.tcl,v 3.2.2.12 2000/12/16 01:51:42 cnk Exp
    @param group_type the group type
    @param group_type_pretty_name pretty name for the group type
    @param column_name name of the column
    @param pretty_name display name
    @param column_type the pretty column type
    @param column_actual_type SQL column type 
    @param column_extra extra info (not null, identity)
    @param after optional to do afterwards 
} {
    group_type:notnull
    group_type_pretty_name:notnull
    column_name:notnull,sql_identifier
    pretty_name:notnull
    column_type:notnull
    column_actual_type:notnull
    column_extra
    after:optional
} -validate {
    not_null_and_special -requires {column_type:notnull column_extra} {
	if { [regexp -nocase {not null} $column_extra ] && [ string match $column_type "special"] } {
	    ad_complain "You may not define a column as \"not null\"
and then define the column type as \"special\". The \"special\" column
type does not have any input widget associated with it; it is used for
columns that you do not want to be hand editable - such as those that
are filled by triggers or other automatic events."
	}
    }
}


# putting this semi-private error return here so that the transaction
# code is a little more readable

proc my_error_return {} {
    upvar errmsg errmsg
    ad_return_error "Insert failed" "Insertion of your group type field in the database failed.  Here's what the RDBMS had to say:
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>
You should back up, edit the form to fix whatever problem is mentioned 
above, and then resubmit.
"
   ad_script_abort
}

set table_name [ad_user_group_helper_table_name $group_type]

set alter_sql "alter table $table_name add ($column_name $column_actual_type $column_extra)"

if { [exists_and_not_null after] } {
    set sort_key [expr $after + 1]
    set update_sql "update user_group_type_fields
set sort_key = sort_key + 1
where group_type = :group_type
and sort_key > :after"
} else {
    set sort_key [db_string max_sort_key "select nvl(max(sort_key)+1,1) from user_group_type_fields where group_type = :group_type"]
    set update_sql ""
}

set insert_sql "insert into user_group_type_fields (group_type, column_name, pretty_name, column_type, column_actual_type, column_extra, sort_key)
values
( :group_type, :column_name, :pretty_name,:column_type, :column_actual_type, :column_extra, :sort_key)"


# first alter the table
if [ catch { db_dml alter_table_add_field $alter_sql } errmsg ] {
    my_error_return
}

# then try the meta date and sort order updates
db_transaction {
    db_dml insert_new_ugt_fields $insert_sql
    if { ![empty_string_p $update_sql] } {
	db_dml update_ug_type_fields $update_sql
    }
} on_error {
    # an error
    # need to TRY to reverse the alter table statement
    catch {db_dml reverse_column_add "alter table $table_name drop column $column_name"}
    my_error_return
}

# database stuff went OK
set page_html "[ad_admin_header "Field Added"]

<h2>Field Added</h2>

to <a href=\"group-type?[export_url_vars group_type]\">the $group_type_pretty_name</a> group type

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
doc_return  200 text/html $page_html
