# $Id: issue-edit.tcl,v 3.0.4.1 2000/04/28 15:08:39 carsten Exp $
set_the_usual_form_variables
# issue_id

set return_url "[ns_conn url]?[export_entire_form_as_url_vars]"

set customer_service_rep [ad_get_user_id]

if {$customer_service_rep == 0} {
    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

ReturnHeaders

set page_title "Edit Issue #$issue_id"
ns_write "[ad_admin_header $page_title]
<h2>$page_title</h2>

[ad_admin_context_bar [list "../index.tcl" "Ecommerce"] [list "index.tcl" "Customer Service Administration"] $page_title]

<hr>
"

set db [ns_db gethandle]
set issue_type_list [database_to_tcl_list $db "select issue_type from ec_cs_issue_type_map where issue_id=$issue_id"]

ns_write "
If you are not [database_to_tcl_string $db "select first_names || ' ' || last_name from users where user_id=$customer_service_rep"], please <a href=\"/register.tcl?[export_url_vars return_url]\">log in</a>

<p>

<form method=post action=issue-edit-2.tcl>
[export_form_vars issue_id]

Modify Issue Type:
<blockquote>
[ec_issue_type_widget $db $issue_type_list]
</blockquote>

<p>

<center>
<input type=submit value=\"Submit Changes\">
</center>

</form>

[ad_admin_footer]
"
