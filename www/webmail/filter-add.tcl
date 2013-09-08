# /webmail/filter-add.tcl

ad_page_contract {
    Add a filter to the list of current filters.

    @author Jin Choi (jsc@arsdigita.com)
    @creation-date 2000-02-23
    @cvs-id filter-add.tcl,v 1.4.2.5 2000/08/13 20:04:25 mbryzek Exp
} {
    filter_type
    filter_term:allhtml
}

set filters [ad_get_client_property -browser t "webmail" "filters"]

set new_filter [list $filter_type $filter_term]

if { [lsearch -exact $filters $new_filter] == -1 } {
    lappend filters $new_filter
    ad_set_client_property -browser t "webmail" "filters" $filters
}

ad_returnredirect ""