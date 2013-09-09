# /www/address-book/record-delete.tcl

ad_page_contract {

    deletes address book record
    
    @param scope
    @param user_id
    @param group_id
    @param address_book_id
    @param return_url

    @cvs-id record-delete.tcl,v 3.2.2.11 2000/10/10 14:46:35 luke Exp
    @creation-date 12/24/99
    @author teadams@arsdigita.com
    @author tarik@arsdigita.com
} {
    scope:optional
    user_id:optional,integer
    group_id:optional,integer
    address_book_id:integer
    return_url:optional
}

ad_scope_error_check user

ad_scope_authorize $scope none group_admin user

db_1row address_book_select_all "
select first_names, 
       last_name,
       email, 
       email2, 
       line1, 
       line2, 
       city, 
       usps_abbrev,  
       zip_code, 
       country,
       phone_home, 
       phone_work, 
       phone_cell, 
       phone_other, 
       birthday, 
       birthmonth,
       birthyear, 
       notes
from   address_book 
where  address_book_id = :address_book_id"

doc_return  200 text/html  "
[ad_scope_header "Delete $first_names $last_name"]
[ad_scope_page_title "Delete $first_names $last_name"]
[ad_scope_context_bar_ws \
	[list "index?[export_url_scope_vars return_url]" "Address book"] \
	"Delete record"]

<hr>

[ad_scope_navbar]

<form method=post action=record-delete-2>

[export_form_scope_vars address_book_id return_url]

<p>Are you sure you want to delete the record for $first_names $last_name?

<p>
<center>
<input type=submit name=yes_submit value=\"Yes, I want to delete it\">
</center>
</form>

[ad_scope_footer]
"



