ad_page_contract {
    @cvs-id columns-add.tcl,v 3.1.2.9 2000/10/10 14:46:34 luke Exp
    Code for columns-add.tcl
} {
}

ad_maybe_redirect_for_registration

set page_content "
[ad_header "Add a column"]

<h2>Add a column</h2>

[ad_context_bar_ws [list "" "Address Book"] "Add a viewable column"]

<hr>

<form method=POST action=\"columns-add-2.tcl\"> 

<table>
<tr><th valign=top align=right>Column name in database:</th>
<td><input type=text size=40 name=column_name MAXLENGTH=100></td></tr>

<tr><th valign=top align=right>Extra Select Statements (ie combinations)</th>
<td><input type=text size=70 name=extra_select MAXLENGTH=4000></td></tr>

<tr><th valign=top align=right>Pretty Name for Column:</th>
<td><input type=text size=70 name=pretty_name MAXLENGTH=4000></td></tr>

<tr><th valign=top align=right>Display order:</th>
<td><input type=text size=3 name=sort_order MAXLENGTH=22></td></tr>

</table>

<p>
<center>
<input type=submit value=\"Add the column\">
</center>
</form>
<p>
[ad_footer]"

doc_return  200 text/html $page_content