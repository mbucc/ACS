ad_page_contract {
    @cvs-id one-case.tcl,v 3.2.2.3 2000/09/22 01:36:01 kevin Exp
} {
    stolen_id:integer   
}

db_1row info_get "select stolen_id,
 additional_contact_info, manufacturer, model, serial_number,
 value, recovered_p, recovered_by_this_service_p, posted,
 story, s.deleted_p, u.email, u.first_names, u.last_name
from stolen_registry s, users u
where stolen_id=:stolen_id
and u.user_id = s.user_id"
db_release_unused_handles


set html "[ad_admin_header "$manufacturer $model $serial_number"]

<h2>$manufacturer $model</h2>

[ad_admin_context_bar [list "index.tcl" "Registry"] "One Entry"]

<hr>

serial number  $serial_number<p>
"

if { $story != "" } {

    append html "<h3>Story</h3>

$story

"

}

append html "<h3>Contact</h3>
Reported on $posted by $first_names $last_name (<a href=\"mailto:$email\">$email</a>)"

if { $additional_contact_info != "" } {

    append html ", who may also be reached at <blockquote><pre>
$additional_contact_info
</pre></blockquote>"

}

append html "
<ul>
<li><a href=\"delete?stolen_id=$stolen_id&manufacturer=[ns_urlencode $manufacturer]\">Delete</a> this post

<p>
<form action=update-manufacturer>
<input type=hidden name=stolen_id value=$stolen_id>
<li><input type=text value=\"$manufacturer\" name=manufacturer size=20>
    <input type=submit value=\"Update manufacturer\">
</ul>
</form>

[ad_admin_footer]
"

db_release_unused_handles
doc_return 200 text/html $html
