# /www/address-book/record-add.tcl

ad_page_contract {
    Adds an address book record

    @param scope
    @param user_id
    @param group_id
    @param return_url
    @param name

    @author teadams@arsdigita.com
    @author tarik@arsdigita.com
    @creation-date 12/24/99
    @cvs-id record-add.tcl,v 3.3.2.15 2001/01/09 22:08:15 khy Exp
} {
    scope:optional
    user_id:optional,integer
    group_id:optional,integer
    return_url:optional
    name:optional
}

if {[ad_read_only_p]} {
    ad_scope_return_read_only_maintenance_message
    return
}

ad_scope_error_check user


ad_scope_authorize $scope none group_admin user

set name [address_book_name]
set address_book_id [db_nextval "address_book_id_sequence"]

set page ""

append page "
[ad_scope_header "Add a Record"]
[ad_scope_page_title "Add a record for $name"]

[ad_scope_context_bar_ws [list "index.tcl?[export_url_scope_vars]" "Address book"] "Add"]

<hr>
[ad_scope_navbar]
<form method=post action=\"record-add-2\">
[export_form_vars -sign address_book_id] 
[export_form_scope_vars return_url]
<table>
<tr><td>Name</td><td><input type=text name=first_names size=15> <input type=text name=last_name size=25></td></tr>
<tr><td>Email</td><td><input type=text name=email size=30></td></tr>
<tr><td>Email #2</td><td><input type=text name=email2 size=30></td></tr>
<tr><td valign=top>Address</td><td><input type=text name=line1 size=30><br>
<input type=text name=line2 size=30></td></tr>
<tr><td>City</td><td><input type=text name=city size=15> 
  State <select name=usps_abbrev>"


db_foreach state_info {
    select usps_abbrev, state_name from states
} { 
    append page "<option value=$usps_abbrev> $state_name"
}	

append page "
</select>
Zip <input type=text name=zip_code size=10></td></tr>
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



doc_return  200 text/html $page
