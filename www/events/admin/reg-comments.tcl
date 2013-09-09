# File:  events/admin/reg-comments.tcl
# Owner: bryanche@arsdigita.com
# Purpose:  Update comments for one registration.
#####

ad_page_contract {
    Update comments for one registration.

    @param reg_id the registration whose comments we're updating

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id reg-comments.tcl,v 3.6.6.4 2000/09/22 01:37:39 kevin Exp
} {
    {reg_id:integer,notnull}
}


db_1row sel_comments "
 select r.comments, p.event_id, r.reg_date, u.first_names, u.last_name
   from events_registrations r, events_events e, users u, events_prices p
  where p.event_id = e.event_id
    and u.user_id = r.user_id
    and r.reg_id = $reg_id
    and p.price_id = r.price_id
"

append whole_page "
   [ad_header "Add/Edit Comments Regarding Registration #$reg_id"]
<h2>Add/Edit Comments Regarding Registration #$reg_id</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] "Registration"]
<hr>

<h3>Comments</h3>

on this order from $first_names $last_name on $reg_date for 
[events_event_name $event_id]

<form method=post action=reg-comments-2>
[philg_hidden_input reg_id $reg_id]

<textarea name=comments rows=10 cols=70 wrap=soft>$comments</textarea>
<center> <input type=submit value=\"Submit Comments\"> </center>
</form>
[ad_footer]
"


doc_return  200 text/html $whole_page
##### EOF
