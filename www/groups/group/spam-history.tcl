# File: /groups/group/spam-history.tcl
ad_page_contract {
    @param user_id the ID of the user to look at

    @cvs-id spam-history.tcl,v 3.4.2.6 2000/09/22 01:38:15 kevin Exp
} {
    user_id:naturalnum,notnull
}   

set group_name [ns_set get $group_vars_set group_name]


ad_scope_authorize $scope all group_member none

set first_names [db_string get_first_name "
select first_names 
from users
where user_id=:user_id "]

set last_name [db_string get_last_name "
select last_name
from users
where user_id=:user_id "]



set page_html "
[ad_scope_header "Email History"]
[ad_scope_page_title "Email History of $first_names $last_name"]
[ad_scope_context_bar_ws_or_index [list index $group_name] [list spam-index "Email"] "History"]
<hr>
"
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


db_foreach select_gs_history_details "select spam_id, send_date, approved_p, subject, sender_ip_address, from_address, send_to, creation_date, n_receivers_intended, n_receivers_actual
from group_spam_history
where sender_id = :user_id
and group_id = :group_id 
order by creation_date desc" { 


    incr counter
    
    set approved_string [ad_decode $send_date "" "N/A" $send_date]
    set approval_state_string [ad_decode $approved_p "f" "Disapproved"\
	    "t" "$approved_string" "Waiting"]

    set subject [ad_decode $subject "" None $subject]

    append html "
    <tr>
    <td>$sender_ip_address
    <td>$from_address
    <td>[join $send_to ", "]
    <td><a href=\"spam-item?[export_url_vars spam_id]\">$subject</a>
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

doc_return  200 text/html  "
$page_html
<blockquote>
$html
</blockquote>
<p><br>
[ad_scope_footer]
"

