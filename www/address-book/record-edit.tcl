# $Id: record-edit.tcl,v 3.0 2000/02/06 02:44:22 ron Exp $
# File:     /address-book/index.tcl
# Date:     12/24/99
# Contact:  teadams@arsdigita.com, tarik@arsdigita.com
# Purpose:  address book main page
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

if {[ad_read_only_p]} {
    ad_scope_return_read_only_maintenance_message
    return
}

set_the_usual_form_variables 0
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)
# address_book_id

ad_scope_error_check user
set db [ns_db gethandle]

ad_scope_authorize $db $scope none group_admin user

set name [address_book_name $db]

set selection [ns_db 1row $db "select * from address_book where address_book_id=$address_book_id"]
set_variables_after_query


ns_return 200 text/html "
[ad_scope_header "Edit record " $db]
[ad_scope_page_title "Edit record" $db]

[ad_scope_context_bar_ws [list "index.tcl?[export_url_scope_vars return_url]" "Address book"] "Edit"]
<hr>
[ad_scope_navbar]
<form method=post action=\"record-edit-2.tcl\">
[export_form_scope_vars address_book_id return_url]
<table>
<tr><td>Name</td><td><input type=text name=first_names size=15 value=\"[philg_quote_double_quotes $first_names]\"> <input type=text name=last_name size=25 value=\"[philg_quote_double_quotes $last_name]\"></td></tr>
<tr><td>Email</td><td><input type=text name=email size=30 value=\"[philg_quote_double_quotes $email]\"></td></tr>
<tr><td>Email #2</td><td><input type=text name=email2 size=30 value=\"[philg_quote_double_quotes $email2]\"></td></tr>
<tr><td valign=top>Address</td><td><input type=text name=line1 size=30 value=\"[philg_quote_double_quotes $line1]\"><br>
<input type=text name=line2 size=30 value=\"[philg_quote_double_quotes $line2]\"></td></tr>
<tr><td>City</td><td><input type=text name=city size=15 value=\"[philg_quote_double_quotes $city]\"> State <input type=text name=usps_abbrev size=2 value=\"[philg_quote_double_quotes $usps_abbrev]\"> Zip <input type=text name=zip_code size=10 value=\"[philg_quote_double_quotes $zip_code]\"></td></tr>
<tr><td>Country</td><td><input type=text name=country size=30 value=\"[philg_quote_double_quotes $country]\"></td></tr>
<tr><td>Phone (home)</td><td><input type=text name=phone_home size=15 value=\"[philg_quote_double_quotes $phone_home]\"></td></tr>
<tr><td>Phone (work)</td><td><input type=text name=phone_work size=15 value=\"[philg_quote_double_quotes $phone_work]\"></td></tr>
<tr><td>Phone (cell)</td><td><input type=text name=phone_cell size=15 value=\"[philg_quote_double_quotes $phone_cell]\"></td></tr>
<tr><td>Phone (other)</td><td><input type=text name=phone_other size=15 value=\"[philg_quote_double_quotes $phone_other]\"></td></tr>
<tr><td>Birthday</td><td>[address_book_birthday_widget $birthmonth $birthday $birthyear]</td></tr>
<tr><td>Days in advance to remind of birthday</td><td><input type=text name=days_in_advance_to_remind size=2 value=\"[philg_quote_double_quotes $days_in_advance_to_remind]\"> (Enter another value if you want a 2nd reminder: <input type=text name=days_in_advance_to_remind_2 size=2 value=\"[philg_quote_double_quotes $days_in_advance_to_remind_2]\"> )</td></tr>
<tr><td>Notes</td><td><textarea name=notes rows=5 cols=50>$notes</textarea></td></tr>
</table>
<center><input type=submit value=\"Submit Changes\"></center>
</form>
[ad_scope_footer]
"
