ad_page_contract {
    @param column_name
    @cvs-id columns-edit.tcl,v 3.1.2.11 2000/10/10 14:46:34 luke Exp
    This file should be called columns-edit.tcl
    Called from columns-list.tcl
    
} {
    column_name:notnull
}

ad_maybe_redirect_for_registration
db_1row address_book_get_column_data "
    select column_name, extra_select, pretty_name, sort_order
    from address_book_viewable_columns 
    where column_name=:column_name"

#now we have the values from the database.



set page_content "
[ad_header "Edit the entry for $pretty_name"]

<h2>Edit the entry for $pretty_name</h2>

[ad_context_bar_ws [list "" "Address Book"]  "Edit a column"]

<hr>

<form method=POST action=columns-edit-2>
" 

# -- Gary's Hot Fix --
# Someone decided to use column_name as a prmky
# So I have to go in and app

#set up a temp var name

set temp_key $column_name

# Make the forms:

append page_content "
[export_form_vars temp_key]

<table>
<tr><th valign=top align=right>Column name in database:</th>
<td><input type=text size=40 MAXLENGTH=100 name=column_name value=\"[philg_quote_double_quotes $column_name]\"></td></tr>

<tr><th valign=top align=right>Extra Select Statements (ie combinations)</th>
<td><input type=text size=70 MAXLENGTH=4000 name=extra_select value=\"[philg_quote_double_quotes $extra_select]\"></td></tr>

<tr><th valign=top align=right>Pretty Name for Column:</th>
<td><input type=text size=70 MAXLENGTH=4000 name=pretty_name value=\"[philg_quote_double_quotes $pretty_name]\"></td></tr>

<tr><th valign=top align=right>Display order:</th>
<td><input type=text size=3  MAXLENGTH=22 name=sort_order value=\"[philg_quote_double_quotes $sort_order]\"></td></tr>

</table>
<p>
<center>
<input type=submit value=\"Edit [philg_quote_double_quotes $pretty_name] \">
</center>
</form>
<p>
[ad_footer]"



doc_return  200 text/html $page_content