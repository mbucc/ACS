# $Id: picklist-row-delete.tcl,v 3.0.4.1 2000/04/28 15:08:40 carsten Exp $
set_the_usual_form_variables
# table_name, rowid

set db [ns_db gethandle]

ns_db dml $db "delete from $table_name where rowid='$QQrowid'"

ad_returnredirect picklists.tcl