# $Id: category-enable-toggle.tcl,v 3.0.4.1 2000/04/28 15:08:26 carsten Exp $

set_the_usual_form_variables

# category

set db [ns_db gethandle]

ns_db dml $db "update calendar_categories set enabled_p = logical_negation(enabled_p) where category = '$QQcategory'"

ad_returnredirect "category-one.tcl?[export_url_vars category]"

