# /www/pvt/toggle-dont-spam-me-p.tcl
ad_page_contract {
    Toggle the don't spam me preference.

    @author
    @creation-date
    @cvs-id toggle-dont-spam-me-p.tcl,v 3.1.8.3 2000/07/21 04:03:46 ron Exp
} {

}


set user_id [ad_get_user_id]

db_dml "toggle_spam_me" "update users_preferences set dont_spam_me_p = logical_negation(dont_spam_me_p) where user_id = :user_id" -bind [ad_tcl_vars_to_ns_set user_id]

ad_returnredirect "home.tcl"
