# spamees-view.tcl,v 1.1.2.2 2000/02/03 09:50:05 ron Exp
set_the_usual_form_variables
#sql_post_select

if {![exists_and_not_null sql_post_select]} {
    ad_return_complaint 1 "<li>You have entered this page without
    a sql_post_select variable"
}

ReturnHeaders 

ns_write "[ad_admin_header "Spam"]

<h2>Spam</h2>

[ad_context_bar_ws [list "../index.tcl" "Events Administration"] [list "action-choose.tcl?[export_url_vars sql_post_select]" "Spam"] "Spamees"]

<hr>
You are spamming the following people:
<ul>
"
set db [ns_db gethandle]
set selection [ns_db select $db "select users.email $sql_post_select"]
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    ns_write "<li>$email"
}

ns_write "</ul>[ad_footer]"
