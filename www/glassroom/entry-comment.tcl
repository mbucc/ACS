# $Id: entry-comment.tcl,v 3.0.4.1 2000/04/28 15:10:42 carsten Exp $
# entry-comment.tcl -- show existing comments for a logbook entry,
#                      and allow entry of new comments

set_form_variables

# expects entry_id, procedure_name


# check for user

set user_id [ad_verify_and_get_user_id]

if { $user_id == 0 } {
    ad_returnredirect "/register.tcl?return_url=[ns_urlencode [ns_conn url]]"
    return
}


set select_sql "
select entry_time, entry_author, procedure_name, entry_time, 
       first_names || ' ' || last_name as pretty_entry_author, notes
  from glassroom_logbook, users
 where entry_id = $entry_id
       and glassroom_logbook.entry_author = users.user_id
       and users.user_id = entry_author"

set db [ns_db gethandle]

set selection [ns_db 0or1row $db $select_sql]

if { [empty_string_p $selection] } {
    # if it's not there, just redirect them to the index page
    # (if they hacked the URL, they get what they deserve, if the
    # the entry has been deleted, they can see the list of entries for that logbook procedure)
    ad_returnredirect "index.tcl?procedure_name=[ns_urlencode $procedure_name]"
    return
}

set_variables_after_query


# emit page contents


ReturnHeaders

ns_write "[ad_header "Comments on Logbook Entry"]

<h2>Comments on Logbook Entry for $procedure_name</h2>
in [ad_context_bar [list index.tcl Glassroom] [list "logbook-view.tcl?procedure_name=[ns_urlencode $procedure_name]" "View Logbook Entries"] "View Logbook Entry Comments"]
<hr>

<h3>The Logbook Entry for $procedure_name</h3>

<ul>
    <li> <b>Entry Time</b>: [util_AnsiDatetoPrettyDate $entry_time]
         <p>

    <li> <b>Entry Author</b>: $pretty_entry_author
         <p>

    <li> <b>Notes</b>: $notes
         <p>
</ul>
"

set count [database_to_tcl_string $db "select count(*) from general_comments where on_what_id = $entry_id and on_which_table = 'glassroom_logbook'"]

if { $count == 0 } {
    ns_write "There are no comments at this time"
} elseif { $count == 1 } {
    ns_write "There is one comment:"
} else {
    ns_write "There are $count comments:"
}

set select_sql "
select gc.comment_id, gc.user_id, gc.content, gc.html_p, users.first_names || ' ' || users.last_name as commenter_name,
       gc.comment_date
  from general_comments gc, users
 where gc.on_what_id = $entry_id
       and gc.on_which_table = 'glassroom_logbook'
       and gc.user_id = users.user_id
 order by gc.comment_date"


set selection [ns_db select $db $select_sql]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    ns_write "<blockquote>\n[util_maybe_convert_to_html $content $html_p]\n"
    ns_write "<br><br>-- <a href=\"/shared/community-member.tcl?user_id=$user_id\">$commenter_name</a>, [util_AnsiDatetoPrettyDate $comment_date]"
    ns_write "</blockquote>"
}


if { ![ad_read_only_p] } {
    # show 'add new comment'
    ns_write "<hr><blockquote><form action=entry-comment-2.tcl method=POST>
Would you like to add a comment?<p>
[export_form_vars procedure_name entry_id]
<textarea name=content cols=50 rows=5 wrap=soft></textarea><br>
Text above is
<select name=html_p><option value=f>Plain Text<option value=t>HTML</select>
<br>
<input type=submit name=submit value=\"Proceed\"></blockquote>"
} else {
    ns_write "Comments cannot be added at this time"
}


ns_write "
[glassroom_footer]
"
