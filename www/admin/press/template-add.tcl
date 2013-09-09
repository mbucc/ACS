# /www/admin/press/template-add.tcl

ad_page_contract {

    Add a new press release template

    @author  Ron Henderson (ron@arsdigita.com)
    @created December 1999
    @cvs-id  template-add.tcl,v 3.2.2.6 2001/01/11 23:17:17 khy Exp
} {
}

# Grab the site-default template to initialize this template

set default [db_string default_template "
select template_adp 
from   press_templates 
where  template_id = 1"]

# Grab a template id for double-click protection

set template_id [db_string template_id "
select press_template_id_sequence.nextval from dual"]

db_release_unused_handles

# Now write out the form...

doc_return  200 text/html "
[ad_admin_header "Add a Template"]

<h2>Add a Template</h2>

[ad_admin_context_bar [list "" "Press"] "Add a Template"]

<hr>

<form method=post action=template-preview>
<input type=hidden name=target value=template-add-2>
[export_form_vars -sign template_id]
<table>
<tr>
  <td align=right><b>Template Name</b>:</td>
  <td><input type=text name=template_name size=60</td>
</tr>
<tr>
  <td align=right><b>Template ADP</b>:</td>
  <td>
<textarea name=template_adp cols=60 rows=10 wrap>[ns_quotehtml $default]</textarea></td>
</tr>
<tr>
  <td></td>
  <td><input type=submit value=Preview></td>
</tr>
</table>
</form>

<h3>Instructions</h3>

<p>Enter an ADP fragment to specify a press release template.  You can
refer to the following variables:

<dl compact>
<dt><code>&lt;%=\$publication_name%&gt;</code>
<dd>Name of the publication
<dt><code>&lt;%=\$publication_date%&gt;</code>
<dd>When the article was published (date or description)
<dt><code>&lt;%=\$article_title%&gt;</code>
<dd>Name of the article
<dt><code>&lt;%=\$article_pages%&gt;</code>
<dd>Page reference for the article
<dt><code>&lt;%=\$abstract%&gt;</code>
<dd>Abstract or summary of the article
</dl>

[ad_admin_footer]"

