# $Id: record-add.tcl,v 3.0 2000/02/06 02:44:21 ron Exp $
# File:     /address-book/record-add.tcl
# Date:     12/24/99
# Contact:  teadams@arsdigita.com, tarik@arsdigita.com
# Purpose:  adds an address book record
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
# maybe return_url, name

ad_scope_error_check user
set db [ns_db gethandle]

ad_scope_authorize $db $scope none group_admin user

set name [address_book_name $db]
set address_book_id [database_to_tcl_string $db "select address_book_id_sequence.nextval from dual"]

ReturnHeaders

ns_write "
[ad_scope_header "Add a Record" $db]
[ad_scope_page_title "Add a record for $name" $db ]


[ad_scope_context_bar_ws [list "index.tcl?[export_url_scope_vars]" "Address book"] "Add"]

<hr>
[ad_scope_navbar]
<form method=post action=\"record-add-2.tcl\">
[export_form_scope_vars address_book_id return_url]
<table>
<tr><td>Name</td><td><input type=text name=first_names size=15> <input type=text name=last_name size=25></td></tr>
<tr><td>Email</td><td><input type=text name=email size=30></td></tr>
<tr><td>Email #2</td><td><input type=text name=email2 size=30></td></tr>
<tr><td valign=top>Address</td><td><input type=text name=line1 size=30><br>
<input type=text name=line2 size=30></td></tr>
<tr><td>City</td><td><input type=text name=city size=15> State <input type=text name=usps_abbrev size=2> Zip <input type=text name=zip_code size=10></td></tr>
<tr><td>Country</td><td><input type=text name=country size=30 value=\"USA\"></td></tr>
<tr><td>Phone (home)</td><td><input type=text name=phone_home size=15></td></tr>
<tr><td>Phone (work)</td><td><input type=text name=phone_work size=15></td></tr>
<tr><td>Phone (cell)</td><td><input type=text name=phone_cell size=15></td></tr>
<tr><td>Phone (other)</td><td><input type=text name=phone_other size=15></td></tr>
<tr><td>Birthday</td><td>[address_book_birthday_widget]</td></tr>
<tr><td>Days in advance to remind of birthday</td><td><input type=text name=days_in_advance_to_remind size=2 value=\"7\"> (Enter another value if you want a 2nd reminder: <input type=text name=days_in_advance_to_remind_2 size=2> )</td></tr>
<tr><td>Notes</td><td><textarea name=notes rows=5 cols=50></textarea></td></tr>
</table>
<center><input type=submit value=\"Add Record\"></center>
</form>
[ad_scope_footer]
"