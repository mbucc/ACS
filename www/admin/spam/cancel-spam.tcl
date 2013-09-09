# www/admin/spam/cancel-spam.tcl


ad_page_contract {

 Cancel a scheduled spam


    @param spam_id the id of the spam message
    @author hqm@arsdigita.com
    @cvs-id cancel-spam.tcl,v 3.1.8.5 2000/09/22 01:36:05 kevin Exp
} {
  spam_id:integer
}

if {[db_0or1row spam_cancel_prompt "
 select sh.from_address, sh.title, sh.body_plain, sh.user_class_description, 
        send_date, sh.n_sent, users.user_id, users.email, sh.status,
        to_char(sh.creation_date,'YYYY-MM-DD HH24:MI:SS') as creation_time, 
        users.first_names || ' ' || users.last_name as user_name 
from spam_history sh, users
where sh.creation_user = users.user_id
and sh.spam_id = :spam_id"] == 0}
{
    ad_return_error "Couldn't find spam" "Could not find an old spam with an id of $spam_id"
    return
}



append page_content "[ad_admin_header "$title"]

<h2>$title</h2>

[ad_admin_context_bar [list "index.tcl" "Spamming"] "Old Spam"]

<hr>
<blockquote>
"

if {[string compare $status "unsent"] != 0} {
append page_content "<font color=red>This spam has already been sent or cancelled, you cannot cancel it.</font>"
} else {
    db_dml delete_spam "delete from spam_history where spam_id = :spam_id"
    append page_content "Spam ID $spam_id, \"$title\", scheduled for $send_date has been cancelled."
}

append page_content "</blockquote>
<p>
[ad_admin_footer]
"


doc_return  200 text/html $page_content


