# /www/address-book/change-prefs-2.tcl

ad_page_contract {
    @cvs-id change-prefs-2.tcl,v 3.1.2.11 2000/10/10 14:46:34 luke Exp
    
    changes viewing prefs from select box

    store prefs in cookies
} {
    view_columns:multiple
}

set cookies [ns_set get [ns_conn headers] Cookie] 
if { ![regexp {address_book_view_preferences=([^;]*).*$} $cookies {} address_book_view_preferences] } {
    ## default viewing preferences
    set column_names [list \
   "first_names" "last_name" "email" "email1" "phone_home" "phone_work" "phone_cell" "phone_other"]
} else {
    set column_names $address_book_view_preferences
}                                    

ad_scope_error_check user

set user_id [ad_scope_authorize $scope none group_member user]

ad_set_cookie -expires never "address_book_view_preferences" $view_columns

ad_returnredirect "?[export_url_scope_vars]"


