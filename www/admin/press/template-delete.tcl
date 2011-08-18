# Delete a template (confirmation page)
#
# Author: ron@arsdigita.com, January 2000
#
# $Id: template-delete.tcl,v 3.0.4.1 2000/03/15 20:40:14 aure Exp $
# -----------------------------------------------------------------------------

ad_page_variables {template_id}

set db [ns_db gethandle]

# Get the template info

set selection [ns_db 1row $db "
select template_name, template_adp
from   press_templates
where  template_id=$template_id"]

if {[empty_string_p $selection]} {
    ad_return_complaint 1 "<li>The template you selected does not exist"
    return
} else {
    set_variables_after_query
}

# Verify that this template is not being used

set count [database_to_tcl_string $db "
select count(*) from press where template_id=$template_id"]

if {$count > 0} {
    ad_return_complaint 1 "<li>The template you selected is in use by
    $count press items"
    return
}

# Verify that they're not trying to delete the site-wide default

if {$template_id == 1} {
    ad_return_complaint 1 "<li>You cannot delete the site-wide default"
    return
}

ns_db releasehandle $db

# Now put up a confirmation page just to make sure

ns_return 200 text/html "
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
