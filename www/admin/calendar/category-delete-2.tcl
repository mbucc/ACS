# $Id: category-delete-2.tcl,v 3.0.4.1 2000/04/28 15:08:25 carsten Exp $
set_the_usual_form_variables

# category

set db [ns_db gethandle]


# see if there are any calendar entries

set num_category_entries [database_to_tcl_string $db "select count(calendar_id) from calendar where category='$QQcategory'"]

if {$num_category_entries > 0} {

  ns_db dml $db "update calendar_categories set enabled_p ='f' where category='$QQcategory'"

} else {

    ns_db dml $db "delete from calendar_categories where category='$QQcategory'"

}

ad_returnredirect "categories.tcl"

