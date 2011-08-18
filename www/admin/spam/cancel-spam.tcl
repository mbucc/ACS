# $Id: cancel-spam.tcl,v 3.0 2000/02/06 03:30:00 ron Exp $
# cancel-spam.tcl
#
# hqm@arsdigita.com
#
# Cancel a scheduled spam
set_the_usual_form_variables

# spam_id

set db [ns_db gethandle] 

set selection [ns_db 0or1row $db "select sh.from_address, sh.title, sh.body, sh.user_class_description, send_date, to_char(sh.creation_date,'YYYY-MM-DD HH24:MI:SS') as creation_time, sh.n_sent, users.user_id, users.first_names || ' ' || users.last_name as user_name, users.email, sh.status
from spam_history sh, users
where sh.creation_user = users.user_id
and sh.spam_id = $spam_id"]

if { $selection == "" } {
    ad_return_error "Couldn't find spam" "Could not find an old spam with an id of $spam_id"
    return
}

set_variables_after_query

ReturnHeaders

ns_write "[ad_admin_header "$title"]

<h2>$title</h2>

[ad_admin_context_bar [list "index.tcl" "Spamming"] "Old Spam"]

<hr>
<blockquote>
"

if {[string compare $status "unsent"] != 0} {
ns_write "<font color=red>This spam has already been sent or cancelled, you cannot cancel it.</font>"
} else {
    ns_db dml $db "delete from spam_history where spam_id = $spam_id"
    ns_write "Spam ID $spam_id, \"$title\", scheduled for $send_date has been cancelled."
}

ns_write "</blockquote>
<p>
[ad_admin_footer]
"
