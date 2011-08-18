# $Id: spam-item.tcl,v 3.0 2000/02/06 03:46:31 ron Exp $
# File: /groups/group/spam-item.tcl
# Date: Fri Jan 14 19:27:42 EST 2000
# Contact: ahmeds@mit.edu
# Purpose: shows one spam details 
#
# Note: group_id and group_vars_set are already set up in the environment by the ug_serve_section.
#       group_vars_set contains group related variables (group_id, group_name, group_short_name,
#       group_admin_email, group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, 
#       group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables 0
# spam_id 

set group_name [ns_set get $group_vars_set group_name]

set db [ns_db gethandle]
ad_scope_authorize $db $scope all group_member none

set exception_count 0
set exception_text ""

if {[empty_string_p $spam_id] && [empty_string_p $spam_id]} {
    incr exception_count
    append exception_text "
    <li>No spam id was passed"
}


if {$exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

set user_id [ad_verify_and_get_user_id]

ReturnHeaders 

ns_write "
[ad_scope_header "One Email" $db]
[ad_scope_page_title "One Email " $db]
[ad_scope_context_bar_ws_or_index [list index.tcl $group_name]\
    [list spam-index.tcl "Email"] [list spam-history.tcl?[export_url_vars user_id] "History"] "One Email"] 
<hr>
"

set selection [ns_db 0or1row  $db "select *
from group_spam_history 
where spam_id = $spam_id"]

if { [empty_string_p $selection ]} {
    ad_return_complaint 1 "<li>No spam with spam id $spam_id was found in the database."
    return
} 

set_variables_after_query

if { $send_to == "members" } {
    set sendto_string "Members"
} else {
    set sendto_string "Administrators"
}

set status_string [ad_decode $approved_p "t" "Approved on [util_AnsiDatetoPrettyDate $send_date]"\
	"f" "Disapproved" "Waiting for Approval"]

append html "

<table border=0 cellpadding=3>

<tr><th align=left>Status</th> 
    <td>$status_string
</tr>

<tr><th align=left>Date</th><td>[util_AnsiDatetoPrettyDate $creation_date]</td></tr>

<tr><th align=left>From </th><td>$from_address</td></tr>

<tr><th align=left>To </th><td>$sendto_string of $group_name</td></tr>

<tr><th align=left>No. of Intended Recipients </th><td>$n_receivers_intended</td></tr>

<tr><th align=left>No. of Actual Recipients </th><td>$n_receivers_actual</td></tr>

<tr><th align=left>Subject </th><td>$subject</td></tr>

<tr><th align=left valign=top>Message </th><td>
<pre>[ns_quotehtml $body]</pre>
</td></tr>

</table>
"
ns_write "

<blockquote>
$html
</blockquote>

[ad_scope_footer]
"






