# $Id: picklist-value-add.tcl,v 3.0.4.1 2000/04/28 15:08:40 carsten Exp $
set_the_usual_form_variables
# table_name, col_to_insert, val_to_insert

set db [ns_db gethandle]

ns_db dml $db "insert into $table_name
($col_to_insert)
values
('$QQval_to_insert')
"

ad_returnredirect picklists.tcl