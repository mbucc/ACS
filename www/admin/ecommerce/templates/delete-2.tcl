# $Id: delete-2.tcl,v 3.0.4.1 2000/04/28 15:08:57 carsten Exp $
set_the_usual_form_variables
# template_id

# check if this is the template that the admin has assigned as the default
# in which case they'll have to select a new default before they can delete
# this one

set db [ns_db gethandle]
set default_template_id [database_to_tcl_string $db "select default_template
from ec_admin_settings"]

if { $template_id == $default_template_id } {
    ad_return_complaint 1 "You cannot delete this template because it is the default template that 
    products will be displayed with if they are not set to be displayed with a different template.
    <p>
    If you want to delete this template, you can do so by first setting a different template to
    be the default template.  (To do this, go to a different template and click \"Make this template
    be the default template\".)"
    return
}

ns_db dml $db "begin transaction"

# we have to first remove all references to this template in ec_products and ec_category_template_map

ns_db dml $db "update ec_products set template_id=null, last_modified=sysdate, last_modifying_user='$user_id', modified_ip_address='[DoubleApos [ns_conn peeraddr]]' where template_id=$template_id"

ns_db dml $db "delete from ec_category_template_map where template_id=$template_id"

ns_db dml $db "delete from ec_templates where template_id=$template_id"
ad_audit_delete_row $db [list $template_id] [list template_id] ec_templates_audit

ns_db dml $db "end transaction"
ad_returnredirect index.tcl

