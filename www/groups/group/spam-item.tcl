# File: /groups/group/spam-item.tcl
ad_page_contract {
    @param spam_id the ID of the spam Item

    @cvs-id spam-item.tcl,v 3.4.2.5 2000/09/22 01:38:15 kevin Exp
} {
    spam_id:naturalnum,notnull
}

set group_name [ns_set get $group_vars_set group_name]


ad_scope_authorize $scope all group_member none




set user_id [ad_verify_and_get_user_id]



set page_html "
[ad_scope_header "One Email"]
[ad_scope_page_title "One Email "]
[ad_scope_context_bar_ws_or_index [list index $group_name]\
    [list spam-index "Email"] [list spam-history?[export_url_vars user_id] "History"] "One Email"] 
<hr>
"

if { [db_0or1row get_gs_history_for_id "select spam_id,group_id,sender_id,sender_ip_address,subject,body,send_to as sendto, creation_date,approved_p,send_date,n_receivers_intended,n_receivers_actual,from_address
from group_spam_history 
where spam_id = :spam_id"]==0 } {
    ad_return_complaint 1 "<li>No spam with spam id $spam_id was found in the database."
    return
} 



set sendto_string [ad_decode $sendto "members" "Group Members" "all" "Everyone in the group" "administrators" "Group Administrators" $sendto]

set status_string [ad_decode $approved_p "t" "Approved on [util_AnsiDatetoPrettyDate $send_date]"\
	"f" "Disapproved" "Waiting for Approval"]

append html "

<table border=0 cellpadding=3>

<tr><th align=left>Status</th> 
    <td>$status_string
</tr>

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
"



doc_return  200 text/html "
$page_html
<blockquote>
$html
</blockquote>

[ad_scope_footer]
"

