# $Id: add-complete-css-2.tcl,v 3.0 2000/02/06 03:16:19 ron Exp $
# File:     /admin/css/add-complete-css-2.tcl
# Date:     12/26/99
# Author:   ahmeds@arsdigita.com
# Purpose:  target page for adding new style selector
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables
# maybe return_url, css_id, selector, property, value
# maybe scope, maybe scope related variables (group_id, user_id)

set exception_count 0
set exception_text ""

set db [ns_db gethandle]

if {![info exists css_id] || [empty_string_p $css_id] } {
    incr exception_count
    append exception_text "<li>No css_id was supplied."
}

if {![info exists selector] || [empty_string_p $selector] } {
    incr exception_count
    append exception_text "<li>The selector field was empty."
}

if {![info exists property] || [empty_string_p $property] } {
    incr exception_count
    append exception_text "<li>The property field was empty."
}

if {![info exists value] || [empty_string_p $value] } {
    incr exception_count
    append exception_text "<li>The value field was empty."
}

if {$exception_count > 0 } {
    ad_scope_return_complaint $exception_count $exception_text $db
    return
}


if { ![info exists return_url] } {
    set return_url "index.tcl?[export_url_scope_vars]"
}

ad_scope_error_check


ad_dbclick_check_dml $db css_complete css_id $css_id $return_url "
insert into css_complete
([ad_scope_cols_sql], css_id, selector, property, value)
values ([ad_scope_vals_sql], $css_id,'$selector','$property', '$value')
"

