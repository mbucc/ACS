# Edit a template
#
# Author: ron@arsdigita.com, December 1999
#
# $Id: template-edit.tcl,v 3.0.4.1 2000/03/15 20:40:59 aure Exp $
# -----------------------------------------------------------------------------

ad_page_variables {template_id}


# Get the template information from the database

set db [ns_db gethandle]

set selection [ns_db 1row $db "
select template_name, template_adp
from   press_templates
where  template_id=$template_id"]
set_variables_after_query

ns_db releasehandle $db

# Note that template_id = 1 is special - it's the site-wide default
# template. Administrators can edit this template but they cannot
# rename it.

set template_form "
<form method=post action=template-preview>
<input type=hidden name=target value=template-edit-2>"

if {$template_id == 1} {
    append template_form "
    [export_form_vars template_id template_name]
    <table>
    <tr>
    <td align=right><b>Template Name</b>:</td>
    <td>Site-wide default template</td>
    </tr>"
} else {
    append template_form "
    [export_form_vars template_id]
    <table>
    <tr>
    <td align=right><b>Template Name</b>:</td>
    <td><input type=text name=template_name size=60 value=\"$template_name\"></td>
    </tr>"
}

append template_form "
<tr>
<td align=right><b>Template ADP</b>:</td>
<td>
<textarea name=template_adp cols=60 rows=10 wrap>[ns_quotehtml $template_adp]</textarea></td>
</tr>
<tr>
<td></td>
<td><input type=submit value=Preview></td>
</tr>
</table>
</form>"

# -----------------------------------------------------------------------------
# Ship out the form

ns_return 200 text/html "
[ad_admin_header "Edit a Template"]

<h2>Edit a Template</h2>

[ad_admin_context_bar [list "" "Press"] "Edit a Template"]

<hr>

$template_form

[ad_admin_footer]"



