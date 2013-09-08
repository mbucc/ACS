# File: /general-links/link-add.tcl

ad_page_contract {
    Step 1 of 4 in adding link and its association.

    @param on_which_table the table to associate the link with
    @param on_what_id the ID column on the table
    @param item the item that the link is associated with
    @param module the associated module (optional)
    @param return_url the URL to return to
    
    @Creation-date: 2/01/2000
    @Author: tzumainn@arsdigita.com 
    @cvs-id link-add.tcl,v 3.2.2.4 2000/09/22 01:38:04 kevin Exp
} {
    on_which_table:notnull
    on_what_id:notnull
    item:notnull
    {module ""} 
    return_url:notnull
}

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}


#check for the user cookie
set user_id [ad_maybe_redirect_for_registration]

doc_return  200 text/html "
[ad_header "Add a Link to $item (Step 1 of 3)"]

<h2>Add a Link to $item (Step 1 of 3)</h2>

[ad_context_bar_ws [list $return_url $item] "Add a Link to $item (Step 1 of 3)"]

<hr>

<blockquote>
<form action=link-add-2 method=post>
[export_form_vars on_which_table on_what_id item return_url module]

<table>

<tr>
<th align=left>URL:</th>
<td><input type=text name=url value=\"http://\" size=50 maxlength=300></td>
</tr>

<tr>
<th valign=top align=left>Link Title:</th>
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

