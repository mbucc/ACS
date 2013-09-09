# /www/address-book/record-edit.tcl

ad_page_contract {

    @param scope
    @param user_id
    @param group_id
    @param address_book_id

    @cvs-id record-edit.tcl,v 3.2.2.12 2000/10/10 14:46:36 luke Exp
    @creation-date 12/24/99
    @author teadams@arsdigita.com
    @author tarik@arsdigita.com

    Purpose:  address book main page
} {
    scope:optional
    user_id:optional,integer
    group_id:optional,integer
    address_book_id:integer
    return_url:optional
}

if {[ad_read_only_p]} {
    ad_scope_return_read_only_maintenance_message
    return
}

ad_scope_error_check user


ad_scope_authorize $scope none group_admin user

set name [address_book_name]

db_0or1row address_book_select_all "select first_names, last_name,
email, email2, line1, line2, city, usps_abbrev, zip_code, country,
phone_home, phone_work, phone_cell, phone_other, birthday, birthmonth,
birthyear, days_in_advance_to_remind, days_in_advance_to_remind_2, notes
from address_book where address_book_id = :address_book_id"

doc_return  200 text/html "
[ad_scope_header "Edit record "]
[ad_scope_page_title "Edit record"]

[ad_scope_context_bar_ws [list "index?[export_url_scope_vars]" "Address book"] "Edit"]
<hr>
[ad_scope_navbar]
<form method=post action=\"record-edit-2\">
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

db_release_unused_handles