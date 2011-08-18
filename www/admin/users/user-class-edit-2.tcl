# $Id: user-class-edit-2.tcl,v 3.0.4.1 2000/04/28 15:09:38 carsten Exp $
set_the_usual_form_variables

# user_class_id, description, sql_description, sql_post_select, name 
# maybe return_url

set exception_text ""
set exception_count 0

if {[string length $description] > 4000} {
    incr exception_count
    append exception_text "<li>Please limit your description to 4000 characters."
}

if {[string length $sql_description] > 4000} {
    incr exception_count
    append exception_text "<li>Please limit your sql description to 4000 characters."
}

if {[string length $sql_post_select] > 4000} {
    incr exception_count
    append exception_text "<li>Please limit your sql to 4000 characters."
}

if {$exception_count > 1} {
    ad_return_complaint $exception_count $exception_text
    return
}

set db [ns_db gethandle]

ns_db dml $db "update user_classes set name = '$QQname', 
sql_description = '$QQsql_description', 
sql_post_select = '$QQsql_post_select',
description = '$QQdescription'
where user_class_id = $user_class_id"

ad_returnredirect "action-choose.tcl?[export_url_vars user_class_id]"
