# $Id: user-identification-match.tcl,v 3.0 2000/02/06 03:18:30 ron Exp $
set_the_usual_form_variables
# user_identification_id, d_user_id

set exception_count 0
set exception_text ""

if { ![info exists d_user_id] || [empty_string_p $d_user_id] } {
    incr exception_count
    append exception_text "<li>You forgot to pick a registered user to match up this unregistered user with."
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

ReturnHeaders
set page_title "Confirm Match"
ns_write "[ad_admin_header $page_title]
<h2>$page_title</h2>

[ad_admin_context_bar [list "../index.tcl" "Ecommerce"] [list "index.tcl" "Customer Service Administration"] $page_title]

<hr>

Please confirm that you want to make this match.  This cannot be undone.
<center>
<form method=post action=user-identification-match-2.tcl>
[export_form_vars d_user_id user_identification_id]
<input type=submit value=\"Confirm\">
</form>
</center>
[ad_admin_footer]
"