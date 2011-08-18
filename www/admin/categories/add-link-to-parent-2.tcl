# $Id: add-link-to-parent-2.tcl,v 3.1.2.1 2000/04/28 15:08:27 carsten Exp $
#
# /admin/categories/add-link-to-parent-2.tcl
#
# by sskracic@arsdigita.com and michael@yoon.org on October 31, 1999
#
# creates a parent-child relationship between two categories
#

set_the_usual_form_variables

# category_id, parent_category_id

set exception_count 0
set exception_text ""

if {![info exists category_id] || [empty_string_p $category_id]} {
    incr exception_count
    append exception_text "<li>Child category ID is missing\n"
}

if {![info exists parent_category_id] || [empty_string_p $parent_category_id]  || \
    $parent_category_id <= 0} {
    incr exception_count
    append exception_text "<li>Parent category ID is incorrect or missing\n"
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text 
    return
}

set db [ns_db gethandle]

with_transaction $db {

    ns_db dml $db "DELETE FROM category_hierarchy
WHERE child_category_id = $category_id
AND parent_category_id IS NULL"

    ns_db dml $db "INSERT INTO category_hierarchy(child_category_id, parent_category_id)
VALUES ($category_id, $parent_category_id)"

} {
    ad_return_error "Database error" "Database threw an error: $errmsg"
    return
}

ns_db releasehandle $db

ad_returnredirect "edit-parentage.tcl?[export_url_vars category_id]"
