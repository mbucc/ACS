ad_page_contract {
 /www/admin/users/user-class-delete.tcl 

 Deletes a user class
 
 lars@pinds.com, June 5. 2000

 @cvs-id user-class-delete.tcl,v 3.1.2.2.2.2 2000/07/25 06:06:04 jmp Exp
} {
    user_class_id:integer,notnull
}


if { [catch {
    db_dml admin_users_user_class_delete "delete from user_classes where user_class_id = :user_class_id"
} errMsg ] } {
    ad_return_error "Couldn't delete user class" "We had a problem deleting this user class. Here's what the database said:
    <blockquote><pre>[ns_quotehtml $errMsg]</pre></blockquote>"
}

ad_returnredirect index

