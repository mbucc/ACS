# www/registry/one-case.tcl

ad_page_contract {
    @cvs-id one-case.tcl,v 3.2.6.4 2000/09/22 01:39:16 kevin Exp
} {
    stolen_id:integer
}

db_1row one_case "select stolen_id,
 additional_contact_info, manufacturer, model, serial_number,
 value, recovered_p, recovered_by_this_service_p, posted,
 story, s.deleted_p, u.user_id, u.email, u.first_names, u.last_name
 from stolen_registry s, users u
 where stolen_id=:stolen_id
 and u.user_id = s.user_id" -bind [ad_tcl_vars_to_ns_set stolen_id]

set comments_list [ad_general_comments_list $stolen_id stolen_registry $model registry]

db_release_unused_handles

set html "[ad_header "$manufacturer $model $serial_number"]

<h2>$manufacturer $model</h2>

serial number  $serial_number<p>

recorded in the <a href=index>Stolen Equipment Registry</a>

<hr>

"

if { $story != "" } {

    append html "<h3>Story</h3>

$story

"

}

append html "<h3>Contact</h3>
Reported on $posted by 
<a href=\"/shared/community-member?user_id=$user_id\">$first_names $last_name</a>
(<a href=\"mailto:$email\">$email</a>)
"

if { $additional_contact_info != "" } {

    append html ", who may also be reached at <blockquote><pre>
$additional_contact_info
</pre></blockquote>"

}

append html "
<p>
$comments_list

[ad_footer]\n"

doc_return  200 text/html $html
