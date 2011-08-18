# Insert a new template
#
# Author: ron@arsdigita.com, December 1999
#
# $Id: template-add-2.tcl,v 3.0.4.3 2000/04/28 15:09:17 carsten Exp $
# -----------------------------------------------------------------------------

ad_page_variables {
    {template_name}
    {template_adp}
}

set db [ns_db gethandle]

ns_db dml $db "
insert into press_templates
 (template_id,
  template_name,
  template_adp)
values
 (press_template_id_sequence.nextval,
  '[DoubleApos $template_name]',
  '[DoubleApos $template_adp]')"

# Redirect back to the templates page

ad_returnredirect ""
