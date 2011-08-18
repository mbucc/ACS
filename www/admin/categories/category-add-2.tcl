# $Id: category-add-2.tcl,v 3.1.2.1 2000/04/28 15:08:28 carsten Exp $
#
# /admin/categories/category-add-2.tcl
#
# by sskracic@arsdigita.com and michael@yoon.org on October 31, 1999
#
# inserts a new category
#

set_the_usual_form_variables

# category_id, parent_category_id, category, category_description, mailing_list_info,
# enabled_p, profiling_weight, category_type, maybe new_category_type

set exception_count 0
set exception_text ""

if {![info exists category_id] || [empty_string_p $category_id]} {
    incr exception_count
    append exception_text "<li>Category ID is somehow missing.  This is probably a bug in our software."
}

if {![info exists parent_category_id]} {
    set parent_category_id ""
}

if {![info exists category] || [empty_string_p $category]} {
    incr exception_count
    append exception_text "<li>Please enter a category"
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

if {[info exists new_category_type] && ![empty_string_p $new_category_type]} {
    set QQcategory_type $QQnew_category_type
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text 
    return
}

set db [ns_db gethandle]

with_transaction $db {
    ns_db dml $db "insert into categories (category_id, category, category_type, profiling_weight, category_description, mailing_list_info, enabled_p)
values ($category_id, '$QQcategory', '$QQcategory_type', '$profiling_weight', '$QQcategory_description', '$QQmailing_list_info', '$enabled_p')"

    set n_categories [database_to_tcl_string $db "select count(category_id) from categories where category_id = '$QQcategory_id'"]
    if {$n_categories != 1 } {
	error "Category $category not inserted"
    }

    # Even top-level categories have at least one row in category_hierarchy, for which parent_category_id is null.

    if {[empty_string_p $parent_category_id]} {
	set parent_category_id "null"
    }

    ns_db dml $db "insert into category_hierarchy (child_category_id, parent_category_id) values ($category_id, $parent_category_id)"

} {
    ad_return_error "Database error occured inserting $category" $errmsg
    return
}

ns_db releasehandle $db

ad_returnredirect "one.tcl?[export_url_vars category_id]"
