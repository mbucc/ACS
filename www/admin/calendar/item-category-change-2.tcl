# $Id: item-category-change-2.tcl,v 3.0.4.1 2000/04/28 15:08:26 carsten Exp $
set_the_usual_form_variables

# calendar_id,  category

set db [ns_db gethandle]

ns_db dml $db "update calendar set category='$QQcategory' where calendar_id=$calendar_id"

ad_returnredirect "item.tcl?calendar_id=$calendar_id"

