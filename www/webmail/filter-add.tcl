# /webmail/filter-add.tcl
# by jsc@arsdigita.com (2000-02-23)

# Add a filter to the list of current filters.


ad_page_variables {filter_type filter_term}

set filters [ad_get_client_property "webmail" "filters"]

set new_filter [list $filter_type $filter_term]

if { [lsearch -exact $filters $new_filter] == -1 } {
    lappend filters $new_filter
    ad_set_client_property -persistent f "webmail" "filters" $filters
}

ad_returnredirect "index.tcl"