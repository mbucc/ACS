# /www/admin/press/template-edit-2.tcl

ad_page_contract {

    Update a template

    @author  Ron Henderson (ron@arsdigita.com)
    @created December 1999
    @cvs-id  template-edit-2.tcl,v 3.2.6.4 2000/07/23 11:42:13 ron Exp
} {
    {template_id:integer}
    {template_name:trim}
    {template_adp:trim,allhtml}
}

db_dml press_templates_update "
update press_templates
set    template_name = :template_name,
       template_adp  = :template_adp
where  template_id   = :template_id"

db_release_unused_handles

# Redirect back to the templates page

ad_returnredirect ""
