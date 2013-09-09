ad_page_contract {
    Form to add an index exclusion pattern for static pages on a site
    (takes no action).

    @author philg@mit.edu 
    @creation-date November 6, 1999
    @cvs-id add.tcl,v 3.2.2.3 2000/09/22 01:36:10 kevin Exp
} 

doc_return  200 text/html "[ad_admin_header "Add an Exclusion Pattern"]

<h2>Add an Exclusion Pattern</h2>

[ad_admin_context_bar [list "../index.tcl" "Static Content"] "Add Exclusion Pattern"]

<hr>

<form method=POST action=\"add-2\">
<blockquote>
<table>
<tr>
  <th valign=top>match field
  <td valign=top><select name=match_field>
      <option SELECTED>url_stub</option>
      <option>page_title</option>
      <option>page_body</option>
      </select>
<tr>
  <th valign=top>matching method
  <td valign=top><select name=like_or_regexp>
      <option SELECTED>like</option>
      <option>regexp</option>
      </select>
<tr>
  <th valign=top>the pattern itself
  <td valign=top><input type=text name=pattern size=60><br>
      <font size=-1>(with LIKE, <code>%</code> is a wildcard matching 0 or more characters; <code>_</code> (underscore) is a wildcard matching exactly 1 character.)</font>
<tr>
  <th valign=top>comment
  <td valign=top><textarea name=pattern_comment rows=6 cols=50 wrap=soft></textarea><br>
      <font size=-1>(an optional note to your fellow maintainers; you can explain why you want some pages excluded)</font>

</tr>

</table>
</blockquote>
<center>
<input type=submit value=\"Add Pattern\">
</center>
</form>

Note that currently REGEXP matching isn't supported.  Also, the
PAGE_BODY field (an Oracle CLOB type) isn't supported.

[ad_admin_footer]
"
