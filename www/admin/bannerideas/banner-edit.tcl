# $Id: banner-edit.tcl,v 3.0 2000/02/06 02:48:25 ron Exp $
set_the_usual_form_variables

# idea_id

ReturnHeaders

set db [banner_ideas_gethandle]
set selection [ns_db 1row $db "
	select intro, more_url, picture_html, keywords
	from bannerideas 
	where idea_id='[DoubleApos $idea_id]'"]
set_variables_after_query


ns_write "
[ad_admin_header "Edit banner idea"]

<h2>Edit</h2>

[ad_admin_context_bar [list "index.tcl" "Banner Ideas Administration"] "Edit One"]


<hr>

<form method=POST action=banner-edit-2.tcl>
[export_form_vars idea_id] 
<table>
<tr><th valign=top align=right> Idea: </th><td><textarea name=intro cols=60 rows=5 wrap=soft>[ns_striphtml $intro]</textarea></td></tr>

<tr><th valign=top align=right>  URL: </th><td><input type=text size=40 maxlength=200 name=more_url value=\"[philg_quote_double_quotes $more_url]\"></td></tr>

<tr><th valign=top align=right> HTML for picture: </th><td> <textarea name=picture_html cols=60 rows=5 wrap=soft>[ns_quotehtml $picture_html]</textarea>\n\n</td></tr>

<tr><th valing=top align=right> Keywords: </th><td>
<textarea name=keywords cols=60 rows=5 wrap=soft>[ns_quotehtml $keywords]</textarea></td></tr>\n\n
</table>

<p>
<center>
<input type=submit value=\"Edit idea\">
</center>
</form>

[ad_admin_footer]
"
