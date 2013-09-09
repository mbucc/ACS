# /webmail/filter-delete-all.tcl

ad_page_contract {
    Clear all the filters in effect.

    @author Jin Choi (jsc@arsdigita.com)
    @creation-date 2000-02-23
    @cvs-id filter-delete-all.tcl,v 1.3.6.3 2000/08/13 20:04:25 mbryzek Exp
} {}

ad_set_client_property -browser t "webmail" "filters" ""

ad_returnredirect "index"

