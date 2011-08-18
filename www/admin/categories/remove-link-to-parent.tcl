# $Id: remove-link-to-parent.tcl,v 3.1.2.1 2000/04/28 15:08:28 carsten Exp $
#
# /admin/categories/remove-link-to-parent.tcl
#
# by sskracic@arsdigita.com and michael@yoon.org on October 31, 1999
#
# deletes a parent-child relationship between two categories
#

set_the_usual_form_variables

# category_id, parent_category_id

set exception_count 0
set exception_text ""

if {![info exists category_id] || [empty_string_p $category_id]} {
    incr exception_count
    append exception_text "<li>Child category ID missing\n"
}

if {![info exists parent_category_id] || [empty_string_p $parent_category_id]} {
    incr exception_count
    append exception_text "<li>Parent category ID missing\n"
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text 
    return
}

set db [ns_db gethandle]
with_transaction $db {
    ns_db dml $db "DELETE FROM category_hierarchy
	WHERE child_category_id = '$QQcategory_id'
	    AND parent_category_id = '$QQparent_category_id'"
    set parent_count [database_to_tcl_string $db "SELECT COUNT(*)
	FROM category_hierarchy WHERE child_category_id='$QQcategory_id'"]

    #  IMPORTANT!  We must provide each category with at least one parent, even
    # the NULL one, otherwise strange things may happen (categories
    # mysteriously disappear from list etc)

    if {$parent_count == 0} {
	ns_db dml $db "INSERT INTO category_hierarchy
	(child_category_id, parent_category_id) VALUES ('$QQcategory_id', NULL)"
    }
} {
    ad_return_error 1 "Database error" $errmsg
    return
}

ns_db releasehandle $db

ad_returnredirect "edit-parentage.tcl?[export_url_vars category_id]"
