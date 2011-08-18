# $Id: edit-2.tcl,v 3.0.4.1 2000/04/28 15:08:57 carsten Exp $
set_the_usual_form_variables
# template_id, template_name, template

set db [ns_db gethandle]

ns_db dml $db "update ec_templates
set template_name='$QQtemplate_name', template='$QQtemplate'
where template_id=$template_id"

ad_returnredirect index.tcl
