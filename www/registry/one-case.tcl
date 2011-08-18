# $Id: one-case.tcl,v 3.0.4.1 2000/03/17 23:16:18 tzumainn Exp $
set_form_variables

# stolen_id is the only one

set db [ns_db gethandle]

set selection [ns_db 1row $db "select stolen_id,
 additional_contact_info, manufacturer, model, serial_number,
 value, recovered_p, recovered_by_this_service_p, posted,
 story, s.deleted_p, u.user_id, u.email, u.first_names, u.last_name
from stolen_registry s, users u
where stolen_id=$stolen_id
and u.user_id = s.user_id"]

set_variables_after_query

set comments_list [ad_general_comments_list $db $stolen_id stolen_registry $model registry]

ns_db releasehandle $db

ReturnHeaders

ns_write "[ad_header "$manufacturer $model $serial_number"]

<h2>$manufacturer $model</h2>

serial number  $serial_number<p>

recorded in the <a href=index.tcl>Stolen Equipment Registry</a>

<hr>

"

if { $story != "" } {

    ns_write "<h3>Story</h3>

$story

"

}

ns_write "<h3>Contact</h3>
Reported on $posted by 
<a href=\"/shared/community-member.tcl?user_id=$user_id\">$first_names $last_name</a>
(<a href=\"mailto:$email\">$email</a>)
"

if { $additional_contact_info != "" } {

    ns_write ", who may also be reached at <blockquote><pre>
$additional_contact_info
</pre></blockquote>"

}

ns_write "
<p>
$comments_list

[ad_footer]\n"
