# /groups/admin/group/spam-item.tcl

ad_page_contract {
 Purpose:  shows one spam details to be approved/disapproved by the administrator

 Note: group_id and group_vars_set are already set up in the environment by the ug_serve_section.
       group_vars_set contains group related variables (group_id, group_name, group_short_name,
       group_admin_email, group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, 
       group_type_url_p, group_context_bar_list and group_navbar_list)


@param spam_id the ID of the SPAM
@cvs-id spam-item.tcl,v 3.3.2.5 2000/09/22 01:38:13 kevin Exp
} {
    spam_id:notnull,naturalnum
}

set group_name [ns_set get $group_vars_set group_name]


if { [ad_user_group_authorized_admin  [ad_verify_and_get_user_id]  $group_id] != 1 } {
    ad_return_error "Not Authorized" "You are not authorized to see this page"
    return
}


set page_html  "
[ad_scope_admin_header "One Spam"]
[ad_scope_admin_page_title "One Spam"]
[ad_scope_admin_context_bar [list "spam-index" "Spam Admin"] [list "spam-history" "History"] "One Spam"]
<hr>
"

if { [db_0or1row get_spam_user_info "select gsh.*, first_names, last_name, email 
from group_spam_history gsh, users u
where gsh.spam_id = :spam_id
and gsh.sender_id = u.user_id"] ==0 } {
    ad_return_complaint 1 "<li>No spam with spam id $spam_id was found in the database."
    return
} 



set sendto_string [join $send_to ", "] 

if { $approved_p == "t" } {
    set status_string "Approved on [util_AnsiDatetoPrettyDate $send_date]"
} elseif { $approved_p == "f" } {
    set status_string "Disapproved [ad_space 1] 
        \[<a href=\"spam-approve?[export_url_vars spam_id]&approved_p=t\">approve</a>\]"
} else {
    set status_string "Waiting for Approval [ad_space 1] 
        \[<a href=\"spam-approve?[export_url_vars spam_id]&approved_p=t\">approve</a> | 
          <a href=\"spam-approve?[export_url_vars spam_id]&approved_p=f\">disapprove</a>\]"
}


append html "

<table border=0 cellpadding=3>

<tr><th align=left>Submitted By </th>
    <td><a href=\"mailto: $email\">$first_names $last_name</a></td>
</tr>

<tr><th align=left>Status</th> 
    <td>$status_string
</tr>

<tr><td></tr><tr><td></tr>

<tr><th align=left>Date</th><td>[util_AnsiDatetoPrettyDate $creation_date]</td></tr>

<tr><th align=left>From </th><td>$from_address</td></tr>

<tr><th align=left>To </th><td>$sendto_string</td></tr>

<tr><th align=left>No. of Intended Recipients </th><td>$n_receivers_intended</td></tr>

<tr><th align=left>No. of Actual Recipients </th><td>$n_receivers_actual</td></tr>

<tr><th align=left>Subject </th><td>[ad_decode $subject "" none $subject]</td></tr>

<tr><th align=left valign=top>Message </th><td>
<pre>[ns_quotehtml $body]</pre>
</td></tr>

</table>
<p>
"

doc_return  200 text/html "$page_html
<blockquote>
$html
</blockquote>
[ad_scope_admin_footer] 
"


