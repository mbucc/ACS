# Add a new press release template
#
# Author: ron@arsdigita.com, December 1999
#
# $Id: template-add.tcl,v 3.0.4.1 2000/03/15 20:39:18 aure Exp $
# -----------------------------------------------------------------------------

# Grab the site-default template to initialize this template

set db      [ns_db gethandle]
set default [database_to_tcl_string $db "
select template_adp from press_templates where template_id=1"]

ns_db releasehandle $db

# Now write out the form...

ns_return 200 text/html "
[ad_admin_header "Add a Template"]

<h2>Add a Template</h2>

[ad_admin_context_bar [list "" "Press"] "Add a Template"]

<hr>

<form method=post action=template-preview>
<input type=hidden name=target value=template-add-2>
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



