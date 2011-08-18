#
# admin/gp/group-remove.tcl
#
# mark@ciccarello.com
# February 2000
#
# removes a permission on a row for a user group

set_the_usual_form_variables

#
# expects: permission_id, row_id, table_name, group_id
#

set db [ns_db gethandle]

ns_db dml $db "begin ad_general_permissions.revoke_permission('$permission_id'); end;"

ad_returnredirect "one-group.tcl?[export_url_vars group_id table_name row_id]"

