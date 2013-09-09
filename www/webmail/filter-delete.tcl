# /webmail/filter-delete.tcl

ad_page_contract {
    Remove a filter from the list of active filters.
    @author Jin Choi (jsc@arsdigita.com)
    @creation-date 2000-02-23
    @cvs-id filter-delete.tcl,v 1.3.6.4 2000/08/13 20:04:25 mbryzek Exp
} {
    filter:allhtml
}

set filters [ad_get_client_property -browser t "webmail" "filters"]
set to_be_removed $filter

set new_filters [list]
foreach filter $filters {
    if { $filter == $to_be_removed } {
	continue
    } else {
	lappend new_filters $filter
    }
}

ad_set_client_property -browser t "webmail" "filters" $new_filters

ad_returnredirect "index"

