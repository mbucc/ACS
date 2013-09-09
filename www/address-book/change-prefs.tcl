#     File:     /address-book/change-prefs.tcl

ad_page_contract {
    @cvs-id change-prefs.tcl,v 3.1.2.10 2000/10/10 14:46:34 luke Exp
    
    sets up a form to change viewing prefs - called from index.tcl
    store prefs in cookies
} {    
}

set cookies [ns_set get [ns_conn headers] Cookie] 
if { ![regexp {address_book_view_preferences=([^;]*).*$} $cookies {} address_book_view_preferences] } {
    ## default viewing preferences
    set column_names [list \
   "first_names" "last_name" "email" "email2" "phone_home" "phone_work" "phone_cell" "phone_other"]
} else {
    set column_names $address_book_view_preferences
}                                    

ad_scope_error_check user

set user_id [ad_scope_authorize $scope none group_member user]
set addr_book_name [address_book_name]


## make sure all the column names in the cookie are actual column names 
## and create the select list for those in the cookie


set view_options ""
foreach column_name $column_names {

    if {![db_0or1row address_book_get_pretty_name "select 
     pretty_name from address_book_viewable_columns 
     where column_name= :column_name"]} {
           # invalid column - we will ignore
    } else {
	## the column name in cookie was found in the database
	append view_options "<option value=\"$column_name\">$pretty_name</option>\n"
    }
}


## now create select list for those not in the cookie (not viewing in table)

set sql_query "select column_name, pretty_name from address_book_viewable_columns \
	where column_name not in ('[join $column_names {', '}]') order by column_name"


set nonview_options ""

db_foreach address_book_get_column_info "select column_name, pretty_name 
from address_book_viewable_columns 
where column_name not in ('[join $column_names {', '}]') order by column_name" {
    append nonview_options "<option value=\"$column_name\">$pretty_name</option>"
}

set rowcount [db_string address_book_get_column_count "select count(*) from address_book_viewable_columns"]


doc_return  200 text/html " 
[ad_scope_header "Change Preferences for Viewing Address Book for $addr_book_name"]
[ad_scope_page_title "Change Viewing Preferences of Address Book for $addr_book_name"]
[ad_scope_context_bar_ws [list "index?[export_url_scope_vars]" "Address Book"] "Change Preferences"]
<hr>
[ad_scope_navbar]


<script language=\"JavaScript\" src=\"selectmove.js\"></script>



<center>
<form action=\"change-prefs-2.tcl\" method=post>

<table border=\"0\">
<tr>
<td align=center>
<b>Hidden Columns</b><br>
<select multiple size=\"$rowcount\" name=\"nonview_columns\">
$nonview_options
</select>

</td>
<td>
<input type=\"button\" value=\"   >>   \" onclick=\"move(this.form.nonview_columns,this.form.view_columns)\" name=\"B1\"><br>
<input type=\"button\" value=\"   <<   \" onclick=\"move(this.form.view_columns,this.form.nonview_columns)\" name=\"B2\">
</td>
<td align=center>
<b>Viewable Columns</b><br>
<select multiple size=\"$rowcount\" name=\"view_columns\">
$view_options
</select><br>
</td>
<td>
<input type=\"button\" value=\" up \" onclick=\"move_vertical(this.form.view_columns,-1)\">
<br>
<input type=\"button\" value=\" down \" onclick=\"move_vertical(this.form.view_columns,1)\">

</td>
</tr>
<tr><td colspan=3 align=center>
<font size=\"-1\"><a href=\"columns-list.tcl\">Edit Columns</a></font>
<p><br>
<input type=\"submit\" value=\"Change Preferences\" onClick=\"select_all(this.form.view_columns)\">
</td><td></td></tr>
</table>

</form>
</center>

"


