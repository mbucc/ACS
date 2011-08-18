# $Id: category-nuke-2.tcl,v 3.1.2.1 2000/04/28 15:08:28 carsten Exp $
#
# /admin/categories/category-nuke.tcl
#
# by sskracic@arsdigita.com and michael@yoon.org on October 31, 1999
#
# actually nukes a category
#

set_form_variables

# category_id

set db [ns_db gethandle]

if {[database_to_tcl_string $db "
select count(child_category_id)
from category_hierarchy
where parent_category_id = $category_id
"] > 0} {
    ad_return_error "Problem nuking category" \
	"Cannot nuke category until all of its subcategories have been nuked."
    return
}

with_transaction $db {
    ns_db dml $db "delete from users_interests where category_id = '$category_id'"
    ns_db dml $db "delete from category_hierarchy where child_category_id = '$category_id'"
    ns_db dml $db "delete from categories where category_id = '$category_id'"

} {
    ad_return_error "Problem nuking category" "$errmsg"
    return
}

ns_db releasehandle $db

ad_returnredirect "index.tcl"

