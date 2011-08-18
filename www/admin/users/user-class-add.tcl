# $Id: user-class-add.tcl,v 3.0.4.1 2000/04/28 15:09:38 carsten Exp $
set_the_usual_form_variables

# sql_description, query, name, 
# maybe return_url

set db [ns_db gethandle]

set user_class_id [database_to_tcl_string $db "select user_class_id_seq.nextval from dual"]

regexp -nocase {^select[^=><-]*(from.*)} $query match sql_post_select

if {![info exists sql_post_select] || [empty_string_p $sql_post_select]} {
    ad_return_complaint 1 "<li>Your query does not start with select clause or does not contain \"from\"."
    return
}

ns_db dml $db "insert into user_classes (user_class_id, name, sql_description, 
sql_post_select) select  $user_class_id, '$QQname', '$QQsql_description', '[DoubleApos $sql_post_select]'
from dual where not exists 
(select 1 from user_classes where name = '$QQname')"

ad_returnredirect "action-choose.tcl?[export_url_vars user_class_id]"
