# /www/user-please-login.tcl
ad_page_contract {
    Redirect to the register page.
    @author
    @creation-date
    @cvs-id user-please-login.tcl,v 3.1.6.1 2000/07/25 11:27:51 ron Exp
} {
}
ad_returnredirect "register/index.tcl?[ns_conn query]"
