# $Id: one-user.tcl,v 3.0.4.1 2000/03/17 08:23:28 mbryzek Exp $
# File: /www/intranet/vacations/one-user.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Purpose: Shows absence info about one user
#

set_the_usual_form_variables 0
# user_id

set caller_id [ad_get_user_id]

if { ![exists_and_not_null user_id] } {
    set user_id $caller_id
}

set db [ns_db gethandle]

if { $caller_id == $user_id } {
    set page_title "Your vacations"
} else {
    set user_name [database_to_tcl_string $db "select first_names || ' ' || last_name from users where user_id=$user_id"]
    set page_title "Vacations for $user_name"
}

set page_body "
[ad_header "$page_title"]
<h2>$page_title</h2>

[ad_context_bar [list "../index.tcl" "Intranet"] [list index.tcl "Vacations"] "One user"]

<hr>
<h3>Your vacations</h3>

<ul>"

set sql_query  "select vacation_id, start_date, end_date, description, contact_info,  decode(vacation_type, '', 'unclassified', vacation_type) as vacation_type
     from user_vacations where user_id = $user_id
     order by start_date desc"

set selection [ns_db select $db $sql_query] 

set counter 0
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    incr counter
    append vacation_text "<li>[nmc_IllustraDatetoPrettyDate $start_date]-[nmc_IllustraDatetoPrettyDate $end_date], <b>$vacation_type</b>:
    <br>
    <blockquote>
    Description:
    $description 
    <p>
    Contact info
    $contact_info
    <p>
    <a href=edit.tcl?[export_url_vars vacation_id]>edit</a>
    </blockquote>"
}

if { $counter == 0 } {
    append vacation_text "<li>You have no vacations in the database right now.<p>"
}

append page_body "
$vacation_text
<p><li><a href=\"add.tcl\">Add a vacation</a></ul><p>
[ad_footer]"

ns_db releasehandle $db

ns_return 200 text/html $page_body

