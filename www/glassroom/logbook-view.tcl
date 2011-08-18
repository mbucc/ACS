# $Id: logbook-view.tcl,v 3.0.4.1 2000/04/28 15:10:44 carsten Exp $
# logbook-view.tcl -- view a particular procedure's logbook entries

set_the_usual_form_variables

# Expects procedure_name


# check for user

set user_id [ad_verify_and_get_user_id]

if { $user_id == 0 } {
    ad_returnredirect "/register.tcl?return_url=[ns_urlencode [ns_conn url]]"
    return
}


set db_handles [ns_db gethandle main 2]
set db [lindex $db_handles 0]
set db2 [lindex $db_handles 1]


set select_sql "
select entry_id, entry_time, 
       first_names || ' ' || last_name as pretty_entry_author, notes
  from glassroom_logbook, users
 where procedure_name='$QQprocedure_name'
       and glassroom_logbook.entry_author=users.user_id
       and users.user_id = entry_author
 order by entry_time"

set selection [ns_db select $db $select_sql]

if { [empty_string_p $selection] } {
    # if it's not there, just redirect them to the index page
    # (if they hacked the URL, they get what they deserve, if all the
    # entries for the procedure have been deleted, they can see the list of valid procedures)
    ad_returnredirect index.tcl
    return
}




# emit the page contents

ReturnHeaders

ns_write "[ad_header "Logbook Entries for $procedure_name"]

<h2>Logbook Entries for $procedure_name</h2>
in [ad_context_bar [list index.tcl Glassroom] "View Logbook"]
<hr>

<h3>The Logbook</h3>

<center>
<table border=1 width=90%>"

ns_write "<tr><th>Time</th><th>Author</th><th>Notes</th><th colspan=2>Comments</th></tr>"

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    ns_write "<tr><td>[util_AnsiDatetoPrettyDate $entry_time]</td><td>$pretty_entry_author</td><td>$notes</td><td>"

    # see if there are any comments on this item
    set count [database_to_tcl_string $db2 "select count(*) from general_comments where on_what_id = $entry_id and on_which_table = 'glassroom_logbook'"]

    if { $count > 0 } {
	if { $count == 1 } {
	    set entry_text "comment"
	} else {
	    set entry_text "comments"
	}
	ns_write "$count $entry_text. </td><td><form method=POST action=\"entry-comment.tcl\"><input type=submit name=submit value=\"View $entry_text\">[export_form_vars entry_id procedure_name]</form></td>"
    } else { 
	ns_write "<form method=POST action=\"entry-comment.tcl\"><input type=submit name=submit value=\"Add Comment\">[export_form_vars entry_id procedure_name]</form>"
    }

    ns_write "</td></tr>"
}


ns_write "</table></center><p>

Would you like to <a href=\"logbook-add.adp?procedure_name=[ns_urlencode $procedure_name]\">add a new logbook entry</a>?


[glassroom_footer]
"




