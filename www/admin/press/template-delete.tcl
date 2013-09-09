# /www/admin/press/template-delete.tcl

ad_page_contract {

    Delete a template (confirmation page)

    @author  Ron Henderson (ron@arsdigita.com)
    @created January 2000
    @cvs-id  template-delete.tcl,v 3.1.8.4 2000/09/22 01:35:51 kevin Exp
} {
    {template_id:integer}
}

# Get the template info

if ![db_0or1row template_info "
select template_name, 
       template_adp
from   press_templates
where  template_id = :template_id"] {

    ad_return_complaint 1 "<li>The template you selected does not exist"
    return
}

# Verify that this template is not being used

set count [db_string template_check "select count(*) from press where template_id = :template_id"]

if {$count > 0} {
    ad_return_complaint 1 "<li>The template you selected is in use by
    $count press items and cannot be deleted"
    return
}

# Verify that they're not trying to delete the site-wide default

if {$template_id == 1} {
    ad_return_complaint 1 "<li>You cannot delete the site-wide default"
    return
}

db_release_unused_handles

# Now put up a confirmation page just to make sure

doc_return  200 text/html "
[ad_admin_header "Delete a template"]

<h2>Delete a Template</h2>

[ad_admin_context_bar [list "" "Press"] "Delete a Template"]

<hr>

<p>Please confirm that you want to <b>permanently delete</b> the
template \"$template_name\":

<blockquote>
[press_coverage_preview $template_adp]
</blockquote>

<p>
<form method=post action=template-delete-2?template_id=$template_id>
<center><input type=submit value=\"Yes, I want to delete it\"></center>
</form>

[ad_admin_footer]"
