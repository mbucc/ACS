# $Id: group-type-new-2.tcl,v 3.0.4.1 2000/04/28 15:09:33 carsten Exp $
# File:     /admin/ug/group-type-new.tcl
# Date:     22/12/99
# Contact:  tarik@arsdigita.com
# Purpose:  adding new user group

set_the_usual_form_variables
# everything for user_group_type 

set exception_text ""
set exception_count 0

if { [info exists group_type] && ![empty_string_p $group_type] && [regexp {[^a-zA-Z0-9_]} $group_type] } {
    append exception_text "<li>You can't have spaces, dashes, slashes, quotes, or colons in a group type.  It has to be just alphanumerics and underscores."
    incr exception_count
}

if { [info exists group_type] && ![empty_string_p $group_type] && [string length $group_type] > 20 } {
    append exception_text "<li>You can't have a group type longer than 20 characters."
    incr exception_count
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

set db [ns_db gethandle]

set insert_sql [util_prepare_insert $db "user_group_types" "group_type" $group_type [ns_conn form]]
set helper_table "create table [ad_user_group_helper_table_name $group_type] (
      group_id	primary key references user_groups
)"

if [catch { ns_db dml $db "begin transaction" 
            ns_db dml $db $insert_sql
            ns_db dml $db $helper_table
            ns_db dml $db "end transaction"
          } errmsg] {
    ad_return_error "insert failed" "Insertion of your group type in the database failed.  Here's what the RDBMS had to say:
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>
You should back up, edit the form to fix whatever problem is mentioned 
above, and then resubmit.
"
    return
}

ad_returnredirect "group-type.tcl?group_type=[ns_urlencode $group_type]"
