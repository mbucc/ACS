# $Id: one-case.tcl,v 3.0 2000/02/06 03:28:01 ron Exp $
set_form_variables

# stolen_id is the only one

set db [ns_db gethandle]

set selection [ns_db 1row $db "select stolen_id,
 additional_contact_info, manufacturer, model, serial_number,
 value, recovered_p, recovered_by_this_service_p, posted,
 story, s.deleted_p, u.email, u.first_names, u.last_name
from stolen_registry s, users u
where stolen_id=$stolen_id
and u.user_id = s.user_id"]

set_variables_after_query

ReturnHeaders

ns_write "[ad_admin_header "$manufacturer $model $serial_number"]

<h2>$manufacturer $model</h2>

[ad_admin_context_bar [list "index.tcl" "Registry"] "One Entry"]


<hr>

serial number  $serial_number<p>

"

if { $story != "" } {

    ns_write "<h3>Story</h3>

$story

"

}

ns_write "<h3>Contact</h3>
Reported on $posted by $first_names $last_name (<a href=\"mailto:$email\">$email</a>)"

if { $additional_contact_info != "" } {

    ns_write ", who may also be reached at <blockquote><pre>
$additional_contact_info
</pre></blockquote>"

}

ns_write "
<ul>
<li><a href=\"delete.tcl?stolen_id=$stolen_id&manufacturer=[ns_urlencode $manufacturer]\">Delete</a> this post

<p>
<form action=update-manufacturer.tcl>
<input type=hidden name=stolen_id value=$stolen_id>
<li><input type=text value=\"$manufacturer\" name=manufacturer size=20>
    <input type=submit value=\"Update manufacturer\">
</ul>
</form>

[ad_admin_footer]
"
