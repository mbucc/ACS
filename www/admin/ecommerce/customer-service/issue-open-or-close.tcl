# $Id: issue-open-or-close.tcl,v 3.0.4.1 2000/04/28 15:08:39 carsten Exp $
set_the_usual_form_variables
# issue_id, close_p

set return_url "[ns_conn url]?[export_entire_form_as_url_vars]"

set customer_service_rep [ad_get_user_id]

if {$customer_service_rep == 0} {
    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

ReturnHeaders

if { $close_p == "t" } {
    set page_title "Close Issue #$issue_id"
} else {
    set page_title "Reopen Issue #$issue_id"
}

ns_write "[ad_admin_header $page_title]
<h2>$page_title</h2>

[ad_admin_context_bar [list "../index.tcl" "Ecommerce"] [list "index.tcl" "Customer Service Administration"] $page_title]

<hr>
"

set db [ns_db gethandle]

ns_write "
If you are not [database_to_tcl_string $db "select first_names || ' ' || last_name from users where user_id=$customer_service_rep"], please <a href=\"/register.tcl?[export_url_vars return_url]\">log in</a>

<p>
Please confirm that you wish to [ec_decode $close_p "t" "close" "reopen"] this issue.

<form method=post action=issue-open-or-close-2.tcl>
[export_form_vars issue_id close_p customer_service_rep]

<center>
<input type=submit value=\"Confirm\">
</center>


[ad_admin_footer]
"
