# $Id: spam-history.tcl,v 3.0 2000/02/06 03:46:11 ron Exp $
# File:     /groups/admin/group/spam-history.tcl
# Date:     Mon Jan 17 13:39:51 EST 2000
# Contact:  ahmeds@mit.edu
# Purpose:  shows group spam history
#
# Note: group_id and group_vars_set are already set up in the environment by the ug_serve_section.
#       group_vars_set contains group related variables (group_id, group_name, group_short_name,
#       group_admin_email, group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, 
#       group_type_url_p, group_context_bar_list and group_navbar_list)

set group_name [ns_set get $group_vars_set group_name]

set db [ns_db gethandle]

if { [ad_user_group_authorized_admin  [ad_verify_and_get_user_id]  $group_id $db] != 1 } {
    ad_return_error "Not Authorized" "You are not authorized to see this page"
    return
}

set exception_count 0
set exception_text ""

ReturnHeaders 

ns_write "
[ad_scope_admin_header "Spam History" $db]
[ad_scope_admin_page_title "Spam History" $db]
[ad_scope_admin_context_bar [list "spam-index.tcl" "Spam Admin"] "History"]
<hr>
"
set selection [ns_db select $db "select gsh.*, first_names, last_name , email
from group_spam_history gsh, users u
where gsh.group_id = $group_id
and gsh.sender_id = u.user_id
order by gsh.creation_date desc "]

set counter 0 

append html "
<table border=1 align=center cellpadding=3>

<tr>
<th>Sender</th>
<th>IP Address</th>
<th>From Address</th>
<th>Send To</th>
<th>Subject</th>
<th>Send Date</th>
<th>Approval Date</th>
<th><br>No. of Intended <br> Recipients</th>
<th><br>No. of Actual <br> Recipients</th>
</tr>
"    

while { [ns_db getrow $db $selection ]} {
    set_variables_after_query

    incr counter
    
    set approved_string [ad_decode $send_date "" "N/A" $send_date]
    set approval_state_string [ad_decode $approved_p "f" "Disapproved"\
	    "t" "$approved_string" "Waiting"]

    set subject [ad_decode $subject "" None $subject]

    append html "
    <tr>
    <td><a href=\"mailto:$email\">$first_names $last_name</a>
    <td>$sender_ip_address
    <td>$from_address
    <td>$send_to
    <td><a href=\"spam-item.tcl?[export_url_vars spam_id]\">$subject</a>
    <td>$creation_date
    <td>$approval_state_string
    <td align=center>$n_receivers_intended
    <td align=center>$n_receivers_actual
    </tr>
    "
}


if { $counter > 0 } {
    append html "</table>" 
} else {
    set html "No Email history of $group_name group available in the database."
}


ns_write "
<blockquote>
$html
</blockquote>
<p><br>
[ad_scope_admin_footer] 
"


