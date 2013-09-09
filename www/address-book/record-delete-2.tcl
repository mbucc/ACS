# /www/address-book/record-delete-2.tcl

ad_page_contract {

    deletes address book record

    @param scope
    @param user_id
    @param group_id
    @param yes_submit
    @param no_submit
    @param address_book_id
    @param return_url


    @cvs-id record-delete-2.tcl,v 3.1.6.11 2000/10/10 14:40:33 luke Exp
    @creation-date 12/24/99
    @author teadams@arsdigita.com
    @author tarik@arsdigita.com

} {
    scope:optional
    user_id:optional,integer
    group_id:optional,integer
    yes_submit:optional
    no_submit:optional
    address_book_id:integer
    return_url:optional
}

ad_scope_error_check user

ad_scope_authorize $scope none group_admin user

if {[info exists no_submit]} {
    if {[info exists return_url]} {
	ad_returnredirect $return_url
	return
    } else {
	ad_returnredirect "records?[export_url_vars group_id scope]"
	return
    }
}

db_dml address_book_delete "
delete from address_book 
where  address_book_id = :address_book_id"

db_release_unused_handles

if [info exists return_url] {
    ad_returnredirect $return_url
} else {
    ad_returnredirect "?[export_url_scope_vars]"
}




