# register.tcl

ad_page_contract {
    @cvs_id register.tcl,v 3.1.6.1 2000/07/25 11:27:51 ron Exp
} {}

ad_returnredirect "register/index.tcl?[ns_conn query]"
