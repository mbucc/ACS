# /www/admin/press/template-add-2.tcl

ad_page_contract {

    Insert a new template

    @author  Ron Henderson (ron@arsdigita.com)
    @created December 1999
    @cvs-id  template-add-2.tcl,v 3.2.6.6 2001/01/11 23:17:16 khy Exp
} {
    {template_id:integer,verify}
    {template_name:trim}
    {template_adp:trim,allhtml}
}

#double-click check
set dbl_clk [db_string press_tmplt_dbl_clk "select
count(*) from press_templates
where template_id = :template_id"]

if {$dbl_clk > 0} {
    ad_return_warning "Template Exists" "A template with this ID already
    exists.  Perhaps you double-clicked?"
    return
}

db_dml press_template_add "
insert into press_templates
 (template_id,
  template_name,
  template_adp)
values
 (:template_id,
  :template_name,
  :template_adp)"

# Redirect back to the templates page

ad_returnredirect ""
