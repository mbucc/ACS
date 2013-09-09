# File: /general-links/link-add-without-assoc.tcl

ad_page_contract {
    Step 1 of 4 in adding link WITHOUT association.

    @param return_url the url to return to
    
    @author tzumainn@arsdigita.com
    @creation-date 1 February 2000
    @cvs-id link-add-without-assoc.tcl,v 3.2.2.4 2000/09/22 01:38:04 kevin Exp
} {
    {return_url "index"}
}

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

#check for the user cookie
set user_id [ad_maybe_redirect_for_registration]

doc_return  200 text/html "
[ad_header "Add a Link (Step 1 of 3)"]

<h2>Add a Link (Step 1 of 3)</h2>

[ad_context_bar_ws [list $return_url "General Links"] "Add a Link (Step 1 of 3)"]

<hr>

<blockquote>
<form action=link-add-without-assoc-2 method=post>
[export_form_vars return_url]

<table>

<tr>
<th align=right>URL:</th>
<td><input type=text name=url value=\"http://\" size=50 maxlength=300></td>
</tr>

<tr>
<th valign=top align=right>Link Title:</th>
<td valign=top><input type=text name=link_title size=50 maxlength=100><br><i>Optional - if left blank, our server will look this up</i></td>
</tr>

</table>

</blockquote>
<br>
<center>
<input type=submit name=submit value=\"Proceed to Step 2\">
</center>
</form>
[ad_footer]
"


