# $Id: banner-add.tcl,v 3.0 2000/02/06 02:48:25 ron Exp $
set db [banner_ideas_gethandle]
ReturnHeaders 


ns_write "
[ad_admin_header "Add a banner idea"]

<h2>Add</h2>

[ad_admin_context_bar [list "index.tcl" "Banner Ideas Administration"] "Add One"]


<hr>

<form method=POST action=\"banner-add-2.tcl\">
 
<input type=hidden name=idea_id value=\"[database_to_tcl_string $db "
select idea_id_sequence.nextval from dual"]\">

<table>
<tr><th align=right valign=top>Idea:</th><td><textarea name=intro cols=60 rows=5 wrap=soft></textarea></td></tr>\n\n

<tr><th align=right valign=top>URL:</th><td><input type=text size=60 maxlength=200 name=more_url></td></tr>\n\n

<tr><th align=right valign=top>HTML for picture:</th><td><textarea name=picture_html cols=60 rows=5 wrap=soft></textarea></td></tr>\n\n

<tr><th align=right valign=top>Keywords:</th><td><textarea name=keywords cols=60 rows=5 wrap=soft></textarea></td></tr>\n\n
</table>
<p>
<center>
<input type=submit value=\"Proceed\">
</center>
</form>
<p>
[ad_admin_footer]"
