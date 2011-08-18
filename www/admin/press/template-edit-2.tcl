# Update a template
#
# Author: ron@arsdigita.com, December 1999
#
# $Id: template-edit-2.tcl,v 3.0.4.2 2000/04/28 15:09:17 carsten Exp $
# -----------------------------------------------------------------------------

ad_page_variables {
    {template_id}
    {template_name}
    {template_adp}
}

set db [ns_db gethandle]

ns_db dml $db "
update press_templates
set    template_name = '$template_name',
       template_adp  = '$template_adp'
where  template_id   =  $template_id"

ns_db releasehandle $db

# Redirect back to the templates page

ad_returnredirect ""
