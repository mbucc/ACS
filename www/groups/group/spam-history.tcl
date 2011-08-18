# $Id: spam-history.tcl,v 3.0 2000/02/06 03:46:29 ron Exp $
# File: /groups/group/spam-history.tcl
# Date: Fri Jan 14 19:27:42 EST 2000
# Contact: ahmeds@mit.edu
# Purpose: this page generates the spam history of this user
#
# Note: group_id and group_vars_set are already set up in the environment by the ug_serve_section.
#       group_vars_set contains group related variables (group_id, group_name, group_short_name,
#       group_admin_email, group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, 
#       group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables 0
# user_id 

set group_name [ns_set get $group_vars_set group_name]

set db [ns_db gethandle]
ad_scope_authorize $db $scope all group_member none

set exception_count 0
set exception_text ""

if {[empty_string_p $user_id] && [empty_string_p $user_id]} {
    incr exception_count
    append exception_text "
    <li>No user id was passed"
}


if {$exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

set first_names [database_to_tcl_string $db "
select first_names 
from users
where user_id=$user_id "]

set last_name [database_to_tcl_string $db "
select last_name
from users
where user_id=$user_id "]

ReturnHeaders 

ns_write "
[ad_scope_header "Email History" $db]
[ad_scope_page_title "Email History of $first_names $last_name" $db]
[ad_scope_context_bar_ws_or_index [list index.tcl $group_name] [list spam-index.tcl "Email"] "History"]
<hr>
"
set selection [ns_db select $db "select *
from group_spam_history
where sender_id = $user_id
and group_id = $group_id 
order by creation_date desc"]

set counter 0

append html "
<table border=1 align=center cellpadding=3>

<tr>
<th>IP Address</th>
<th>From Address</th>
<th>Send To</th>
<th>title</th>
<th>Send Date</th>
<th>Approval Date</th>
<th><br>No. of Intended <br> Recipients</th>
<th><br>No. of Actual <br> Recipients</th>
</tr>
"    
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    
    incr counter
    
    set approved_string [ad_decode $send_date "" "N/A" $send_date]
    set approval_state_string [ad_decode $approved_p "f" "Disapproved"\
	    "t" "$approved_string" "Waiting"]

    set subject [ad_decode $subject "" None $subject]

    append html "
    <tr>
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
    set html "No Email history of $first_names $last_name for $group_name group available in the database."
}

ns_write "

<blockquote>
$html
</blockquote>
<p><br>
[ad_scope_footer]
"






