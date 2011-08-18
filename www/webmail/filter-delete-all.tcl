# /webmail/filter-delete-all.tcl
# by jsc@arsdigita.com (2000-02-23)

# Clear all the filters in effect.

ad_set_client_property -persistent f "webmail" "filters" ""

ad_returnredirect "index.tcl"

