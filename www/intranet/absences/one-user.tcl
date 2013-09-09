# /www/intranet/absences/one-user.tcl

ad_page_contract {
    Purpose: Shows absence info about one user

    @param user_id:integer 

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000
   
    @cvs-id one-user.tcl,v 1.3.2.8 2000/09/22 01:38:25 kevin Exp
} {
    { user_id:notnull,naturalnum "" }
}

set return_url [im_url_with_query]

set caller_id [ad_get_user_id]

if { [empty_string_p $user_id] } {
    set user_id $caller_id
}

if { $user_id == $caller_id } {
    set user_can_edit_p 1
    set page_title "Your absences"
} else {
    set user_can_edit_p [im_is_user_site_wide_or_intranet_admin $caller_id]
    set user_name [db_string users_names \
	    "select first_names || ' ' || last_name from users where user_id=:user_id"]
    set page_title "Absences for $user_name"
}

set context_bar [ad_context_bar_ws [list ./ "Work Absences"] "One user"]

set page_content "<ul>\n"

set sql_query  "select vacation_id, start_date, end_date, description, contact_info,  decode(vacation_type, null, 'unclassified', vacation_type) as vacation_type
     from user_vacations where user_id = :user_id
     order by start_date desc"

set counter 0
db_foreach vacation_info_for_one_user $sql_query {
    incr counter
    append vacation_text "<p><li>[util_AnsiDatetoPrettyDate $start_date]-[util_AnsiDatetoPrettyDate $end_date], <b>$vacation_type</b>:
<ul>
  <li> Description: $description 
  <li> Contact info: $contact_info
"
    if { $user_can_edit_p } {
	append vacation_text " <li> <a href=edit?[export_url_vars vacation_id return_url]>Edit this absence</a>"
    }
    append vacation_text "</ul>\n"

}

if { $counter == 0 } {
    append vacation_text "<li>No absences in the database right now.<p>"
}

append page_content "
$vacation_text
<p><li><a href=\"add?[export_url_vars user_id return_url]\">Add an absence</a></ul><p>
"


doc_return  200 text/html [im_return_template]
