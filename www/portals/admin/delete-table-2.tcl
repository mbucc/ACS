#
# /portals/admin/delete-table-2.tcl
#
# deletes portal table from each portal page it appears on and from the available tables
#
# by aure@arsdigita.com and dh@arsdigita.com
#
# Last modified: 10/8/1999
#
# $Id: delete-table-2.tcl,v 3.0.4.2 2000/04/28 15:11:17 carsten Exp $

#ad_page_variables {table_id}
set_the_usual_form_variables
# table_id

set db [ns_db gethandle]

# -------------------------------
# verify the user
set user_id [ad_verify_and_get_user_id]

if  {![info exists group_id]} {
    set group_id ""
}
portal_check_administrator_maybe_redirect $db $user_id $group_id
# -------------------------------

ns_db dml $db  "begin transaction"
ns_db dml $db  "delete from portal_table_page_map where table_id = $table_id"
ns_db dml $db  "delete from portal_tables where table_id = $table_id"
ns_db dml $db  "end transaction"

ad_returnredirect index

