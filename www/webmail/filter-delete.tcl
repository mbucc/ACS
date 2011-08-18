# /webmail/filter-delete.tcl
# by jsc@arsdigita.com (2000-02-23)

# Remove a filter from the list of active filters.

ad_page_variables {filter}

set filters [ad_get_client_property "webmail" "filters"]
set to_be_removed $filter

set new_filters [list]
foreach filter $filters {
    if { $filter == $to_be_removed } {
	continue
    } else {
	lappend new_filters $filter
    }
}

ad_set_client_property -persistent f "webmail" "filters" $new_filters

ad_returnredirect "index.tcl"

