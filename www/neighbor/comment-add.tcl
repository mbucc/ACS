# $Id: comment-add.tcl,v 3.0.4.1 2000/04/28 15:11:13 carsten Exp $
if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set_form_variables

# neighbor_to_neighbor_id

#check for the user cookie
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    ad_returnredirect /register/index.tcl?return_url=[ns_urlencode [ns_conn url]]?[export_url_vars neighbor_to_neighbor_id]
    return
}


set db [ns_db gethandle]

set selection [ns_db 0or1row $db "select about, title, body, html_p
from neighbor_to_neighbor
where neighbor_to_neighbor_id = $neighbor_to_neighbor_id"]

if { $selection == "" } {
    ad_return_error "Can't find the neighbor-to-neighbor item" "Can't find neighbor-to-neighbor #$neighbor_to_neighbor_id"
    return
}

set_variables_after_query

# take care of cases with missing data

ReturnHeaders

ns_write "[ad_header "Add a comment to $about : $title" ]

<h2>Add a comment</h2>

to <A HREF=\"view-one.tcl?[export_url_vars neighbor_to_neighbor_id]\">$about : $title</a>
<hr>

<blockquote>
[util_maybe_convert_to_html $body $html_p]
</blockquote>
<form action=comment-add-2.tcl method=post>
What comment  would you like to add to this item?<br>
<textarea name=content cols=50 rows=5 wrap=soft>
</textarea><br>
Text above is
<select name=html_p><option value=f>Plain Text<option value=t>HTML</select>
<br>
<center>
<input type=submit name=submit value=\"Proceed\">
</center>
[export_form_vars neighbor_to_neighbor_id]
<input type=hidden name=comment_id value=\"[database_to_tcl_string $db "select general_comment_id_sequence.nextval from dual"]\">
</form>


[ad_footer]
"
