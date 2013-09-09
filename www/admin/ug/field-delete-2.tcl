ad_page_contract {
    @param group_type the type of group
    @param column_name the name of the column

    @cvs-id field-delete-2.tcl,v 3.1.6.7 2000/09/22 01:36:12 kevin Exp
} {
    group_type:notnull
    column_name:notnull
}


# putting this semi-private error return here so that the transaction
# code is a little more readable

proc my_error_return {} {
    upvar errmsg errmsg
    ad_return_error "Deletion failed" "Deletion of your group type field in the database failed.  Here's what the RDBMS had to say:
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

# first alter the table
if [ catch { db_dml alter_table_delete_field "alter table $table_name drop column $column_name" } errmsg ] {
    my_error_return
}

db_transaction {
    db_dml group_type_fields_delete "delete from user_group_type_fields
where group_type = :group_type
and column_name = :column_name"
} on_error {
    # could not delete from user_group_type_fields so try to use the info that is still there to reconstruct the column that was dropped.
    catch { db_1row reconstruct_row "select column_actual_type, column_extra 
                                     from user_group_type_fields 
                                     where group_type = :group_type 
                                     and column_name = :column_name"
            db_dml table_re_add "alter table $table_name 
                                 add ($column_name $column_actual_type $column_extra)" 
    } error
    my_error_return
}

set page_html "[ad_admin_header "Field Removed"]

<h2>Field Removed</h2>

from <a href=\"group-type?[export_url_vars group_type]\">the $group_type group type</a>

<hr>

The following action has been taken:

<ul>

<li>the column \"$column_name\" was removed from the table
$table_name.
<li>a row was removed from the table user_group_type_fields.
</ul>

[ad_admin_footer]
"

doc_return  200 text/html $page_html




