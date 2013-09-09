# /www/admin/press/template-delete-2.tcl

ad_page_contract {

    Delete a template

    @author  Ron Henderson (ron@arsdigita.com)
    @created January 2000
    @cvs-id  template-delete-2.tcl,v 3.2.6.3 2000/07/21 03:57:53 ron Exp
} {
    {template_id:integer}
}

# Verify (again) that this template is not being used

set count [db_string template_check "select count(*) from press where template_id = :template_id"]

if {$count > 0} {
    ad_return_complaint 1 "<li>The template you selected is in use by
    $count press items and cannot be deleted"
    return
}

# Delete the template

db_dml template_delete "delete from press_templates where template_id = :template_id"
db_release_unused_handles

# Redirect to the main admin page

ad_returnredirect ""

