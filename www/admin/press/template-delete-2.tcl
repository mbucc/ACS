# Delete a template
#
# Author: ron@arsdigita.com, January 2000
#
# $Id: template-delete-2.tcl,v 3.0.4.2 2000/04/28 15:09:17 carsten Exp $
# -----------------------------------------------------------------------------

ad_page_variables {template_id}

set db [ns_db gethandle]

# Verify (again) that this template is not being used

set count [database_to_tcl_string $db "
select count(*) from press where template_id=$template_id"]

if {$count > 0} {
    ad_return_complaint 1 "<li>The template you selected is in use by
    $count press items"
    return
}

# Delete the template

ns_db dml $db "delete from press_templates where template_id=$template_id"

# Redirect to the main admin page

ad_returnredirect ""

