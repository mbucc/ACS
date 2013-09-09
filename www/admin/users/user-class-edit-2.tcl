ad_page_contract {
    /www/admin/users/user-class-edit-2.tcl

    Update the database with information about a user class

    @cvs-id user-class-edit-2.tcl,v 3.2.2.3.2.2 2000/07/25 06:06:04 jmp Exp
} {
    user_class_id:integer,notnull
    description:notnull
    sql_description:notnull
    sql_post_select:notnull
    name:notnull
    return_url:optional
}



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



db_dml admin_users_user_class_edit_update  "update user_classes set name = :name,
sql_description = :sql_description,
sql_post_select = :sql_post_select,
description = :description
where user_class_id = :user_class_id"

ad_returnredirect "action-choose?[export_url_vars user_class_id]"
