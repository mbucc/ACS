# $Id: merge.tcl,v 3.1 2000/03/09 00:01:39 scott Exp $
set_the_usual_form_variables

# u1, u2 (two user IDs)

set db [ns_db gethandle]

set selection [ns_db 1row $db "select email as u1_email, first_names as u1_first_names, last_name as u1_last_name, registration_date as u1_registration_date, last_visit as u1_last_visit
from users
where user_id = $u1"]
set_variables_after_query

set selection [ns_db 1row $db "select email as u2_email, first_names as u2_first_names, last_name as u2_last_name, registration_date as u2_registration_date, last_visit as u2_last_visit
from users
where user_id = $u2"]
set_variables_after_query


append whole_page "[ad_admin_header "Merge $u1_email with $u2_email"]

<h2>Merge</h2>

$u1_email with $u2_email

<hr>

<table cellspacing=4>
<tr>
<th>&nbsp;
<th>$u1_email
<th>$u2_email
</tr>
<tr>
<td>Name:
<td>$u1_first_names $u1_last_name
<td>$u2_first_names $u2_last_name
</tr>
<tr>
<td>Complete Record:
<td><a target=new_window href=\"../one.tcl?user_id=$u1\">User ID $u1</a>
<td><a target=new_window href=\"../one.tcl?user_id=$u2\">User ID $u2</a>
</tr>
<tr>
<td>Registered:
<td>[util_AnsiDatetoPrettyDate $u1_registration_date]
<td>[util_AnsiDatetoPrettyDate $u2_registration_date]
</tr>
<tr>
<td>Last Visit:
<td>[util_AnsiDatetoPrettyDate $u1_last_visit]
<td>[util_AnsiDatetoPrettyDate $u2_last_visit]
</tr>
<tr>
<td>BBoard Activity:
"

set selection [ns_db 1row $db "select max(posting_time) as u1_most_recent,count(*) as u1_n_postings from bboard where user_id = $u1"]
set_variables_after_query
if { $u1_n_postings > 0 } {
    set u1_most_recent " through [util_AnsiDatetoPrettyDate $u1_most_recent]"
} else {
    set u1_most_recent ""
}

set selection [ns_db 1row $db "select max(posting_time) as u2_most_recent,count(*) as u2_n_postings from bboard where user_id = $u2"]
set_variables_after_query

if { $u2_n_postings > 0 } {
    set u2_most_recent " through [util_AnsiDatetoPrettyDate $u2_most_recent]"
} else {
    set u2_most_recent ""
}
append whole_page "<td>$u1_n_postings $u1_most_recent
<td>$u2_n_postings $u2_most_recent
</tr>
<tr>
<td>Classified Activity:
"

set selection [ns_db 1row $db "select max(posted) as u1_most_recent,count(*) as u1_n_postings from classified_ads where user_id = $u1"]
set_variables_after_query
if { $u1_n_postings > 0 } {
    set u1_most_recent " through [util_AnsiDatetoPrettyDate $u1_most_recent]"
} else {
    set u1_most_recent ""
}

set selection [ns_db 1row $db "select max(posted) as u2_most_recent,count(*) as u2_n_postings from classified_ads where user_id = $u2"]
set_variables_after_query

if { $u2_n_postings > 0 } {
    set u2_most_recent " through [util_AnsiDatetoPrettyDate $u2_most_recent]"
} else {
    set u2_most_recent ""
}
append whole_page "<td>$u1_n_postings $u1_most_recent
<td>$u2_n_postings $u2_most_recent
</tr>
<tr>
<td>Comment Activity:
"

set selection [ns_db 1row $db "select max(posting_time) as u1_most_recent,count(*) as u1_n_postings from comments where user_id = $u1"]
set_variables_after_query
if { $u1_n_postings > 0 } {
    set u1_most_recent " through [util_AnsiDatetoPrettyDate $u1_most_recent]"
} else {
    set u1_most_recent ""
}

set selection [ns_db 1row $db "select max(posting_time) as u2_most_recent,count(*) as u2_n_postings from comments where user_id = $u2"]
set_variables_after_query

if { $u2_n_postings > 0 } {
    set u2_most_recent " through [util_AnsiDatetoPrettyDate $u2_most_recent]"
} else {
    set u2_most_recent ""
}
append whole_page "<td>$u1_n_postings $u1_most_recent
<td>$u2_n_postings $u2_most_recent
</tr>
<tr>
<td>Neighbor Activity:
"

set selection [ns_db 1row $db "select max(posted) as u1_most_recent,count(*) as u1_n_postings from neighbor_to_neighbor where poster_user_id = $u1"]
set_variables_after_query
if { $u1_n_postings > 0 } {
    set u1_most_recent " through [util_AnsiDatetoPrettyDate $u1_most_recent]"
} else {
    set u1_most_recent ""
}

set selection [ns_db 1row $db "select max(posted) as u2_most_recent,count(*) as u2_n_postings from neighbor_to_neighbor where poster_user_id = $u2"]
set_variables_after_query

if { $u2_n_postings > 0 } {
    set u2_most_recent " through [util_AnsiDatetoPrettyDate $u2_most_recent]"
} else {
    set u2_most_recent ""
}
append whole_page "<td>$u1_n_postings $u1_most_recent
<td>$u2_n_postings $u2_most_recent
</tr>
"

append whole_page "
<tr><td colspan=3>&nbsp;</tr>
<tr>
<td>Take Action!
<td align=center><a href=\"merge-2.tcl?source_user_id=$u1&target_user_id=$u2\">---&gt;</a>
<td align=center><a href=\"merge-2.tcl?source_user_id=$u2&target_user_id=$u1\">&lt;---</a>
</tr>
</table>

[ad_admin_footer]
"
ns_db releasehandle $db
ns_return 200 text/html $whole_page
