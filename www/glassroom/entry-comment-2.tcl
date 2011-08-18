# $Id: entry-comment-2.tcl,v 3.0 2000/02/06 03:44:38 ron Exp $
# entry-comment-2.tcl -- preview comment on logbook entry

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set_the_usual_form_variables

# Expects content, html_p, procedure_name, entry_id

# check for bad input

if { ![info exists content] || [empty_string_p $content] } {
    ad_return_complaint 1 "<li>the comment field was empty"
    return
}

ReturnHeaders

ns_write "[ad_header "Confirm comment on $procedure_name entry"]

<h2>Confirm comment</h2>
on $procedure_name Entry

<hr>

The following is your comment as it would appear on the page <i>Comments for Logbook Entry</i>.
If it looks incorrect, please use the back button on your browser to return and
correct it.  Otherwise, press \"Continue\".
<p>
<blockquote>"

if { [info exists html_p] && $html_p == "t" } {
    ns_write "$content
</blockquote>
Note: if the story has lost all of its paragraph breaks then you
probably should have selected \"Plain Text\" rather than HTML.  Use
your browser's Back button to return to the submission form.
"
} else {
    ns_write "[util_convert_plaintext_to_html $content]
</blockquote>

Note: if the story has a bunch of visible HTML tags then you probably
should have selected \"HTML\" rather than \"Plain Text\".  Use your
browser's Back button to return to the submission form.  " 
}

set db [ns_db gethandle]

ns_write "<form action=entry-comment-3.tcl method=post>
<center>
<input type=submit name=submit value=\"Confirm\">
<input type=hidden name=comment_id value=\"[database_to_tcl_string $db "select general_comment_id_sequence.nextval from dual"]\">
</center>
[export_form_vars content html_p procedure_name entry_id]
</form>
[glassroom_footer]
"

