# $Id: category-update.tcl,v 3.1.2.1 2000/04/28 15:08:28 carsten Exp $
#
# /admin/categories/category-update.tcl
#
# by sskracic@arsdigita.com and michael@yoon.org on October 31, 1999
#
# updates the properties of an existing category
#

set_the_usual_form_variables

# category_id, category, mailing_list_info, profiling_weight, enabled_p
# category_type, possibly new_category_type

set exception_count 0
set exception_text ""

if {![info exists category] || [empty_string_p $category]} {
    incr exception_count
    append exception_text "<li>Please enter or select a category."
}

if {[info exists new_category_type] && ![empty_string_p $new_category_type]} {
    set QQcategory_type $QQnew_category_type
}

if {[info exists category_description] && [string length $category_description] > 4000} {
    incr exception_count
    append exception_text "<li>Please limit your category description to 4000 characters"
}

if {[info exists mailing_list_info] && [string length $mailing_list_info] > 4000} {
    incr exception_count
    append exception_text "<li>Please limit your Mailing list information to 4000 characters"
}

if {![info exists profiling_weight] || [empty_string_p $profiling_weight] || \
    [catch {if {[expr $profiling_weight < 0]} {error catch-it} }] } {
    incr exception_count
    append exception_text "<li>Profiling weight missing or less than 0"
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text 
    return
}

set db [ns_db gethandle]

ns_db dml $db "UPDATE categories
SET category = '$QQcategory',
category_type = '$QQcategory_type',
category_description = '$QQcategory_description',
mailing_list_info = '$QQmailing_list_info',
enabled_p = '$QQenabled_p',
profiling_weight = '$QQprofiling_weight'
WHERE category_id = $category_id"

ns_db releasehandle $db

ad_returnredirect "one.tcl?[export_url_vars category_id]"
