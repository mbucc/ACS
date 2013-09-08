ad_page_contract {
    @cvs-id user-class-add.tcl,v 3.2.2.4.2.2 2000/07/25 06:06:04 jmp Exp
} {
    sql_description:notnull
    query:notnull
    name:notnull
    return_url:optional
}


set user_class_id [db_nextval "user_class_id_seq"]

regexp -nocase {^select[^=><-]*(from.*)} $query match sql_post_select

if {![info exists sql_post_select] || [empty_string_p $sql_post_select]} {
    ad_return_complaint 1 "<li>Your query does not start with select clause or does not contain \"from\"."
    return
}

db_dml admin_users_insert_into_user_class "insert into user_classes (user_class_id, name, sql_description, 
sql_post_select) select :user_class_id, :name, :sql_description, '[DoubleApos $sql_post_select]'
from dual where not exists 
(select 1 from user_classes where name = :name)"

ad_returnredirect "action-choose?[export_url_vars user_class_id]"
