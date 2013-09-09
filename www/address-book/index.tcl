# /www/address-book/index.tcl

ad_page_contract {
    address book main page

    @param scope
    @param user_id
    @param group_id
    @param contract_info_only
    @param order_by
    @param desc

    @cvs-id index.tcl,v 3.3.2.21 2000/10/10 14:46:35 luke Exp
    @creation-date 12/24/99
    @author teadams@arsdigita.com
    @author tarik@arsdigita.com
    
} {
    scope:optional
    user_id:optional,integer
    group_id:optional,integer
    contact_info_only:optional
    order_by:optional
    {desc:integer ""}
    {order_last ""}
}

ad_scope_error_check user

set user_id [ad_scope_authorize $scope none group_member user]

set scope_administrator_p [ad_scope_administrator_p $user_id]

set name [address_book_name]


## put column names to view in column_names
set cookies [ns_set get [ns_conn headers] Cookie] 
if { ![regexp {address_book_view_preferences=([^;]*).*$} $cookies {} address_book_view_preferences] } {
    ## default viewing preferences
    set column_names [list \
   "first_names" "last_name" "email" "email2" "phone_home" "phone_work" "phone_cell" "phone_other"]
} else {
    set column_names $address_book_view_preferences
}                                    


set page_content "

[ad_scope_header "All Records for $name"]
[ad_scope_page_title "All Records for $name"]
[ad_scope_context_bar_ws "Address Book"]
<hr>
[ad_scope_navbar]


<!-- search fields -->
<blockquote>
<form method=post action=record-search>
[export_form_scope_vars]
<font face=\"arial, helvetica\"><b>Search</b></font>
<select name=\"search_by\">
<option value=\"last_name\">Last Name: 
<option value=\"first_names\">First Name: 
<option value=\"city\">City:
</select>
<input type=text name=\"search_value\"> &nbsp;

<input type=submit value=\"Search\">

</form>
</blockquote>
<p>
<center>
"



if { ![info exists order_by] } {
    ## default sort
    set order_by_sql "UPPER(last_name), UPPER(first_names)"
    set order_by ""
} else {
    ## primary sort specified
    set order_by_sql "UPPER($order_by)"
}

## secondary sort
if { [info exists order_last] && ![empty_string_p $order_last] && $order_last!=$order_by} {
    append order_by_sql " , UPPER($order_last)"
}


## to switch sorts as you click on a link of the same column, 
## but if you click on a link of a different column, it always sorts ascending

if { $order_last==$order_by } {

    ### clicking on a same column or initial click
    switch $desc {
	"1" { 
	 append order_by_sql " desc"
         set desc ""
         }
	default { set desc "1"}
    }
} else {
    ## we will ascend, but make sure next one is desc
    set desc "1"
}

set order_last $order_by

set rowcount 0

ad_proc display_table_heading { order_by name desc order_last} {
    return "
    <td align=center bgcolor=\"navy\">
<a href=\"index?[export_url_scope_vars order_by desc order_last]\">
<font face=\"arial, helvetica\" color=white><b>$name</b></font></a>
</td>
"
}


append page_content "<table cellpadding=2 cellspacing=0>
<tr>
<td bgcolor=navy>&nbsp;<!-- view --></td>
"

## display table headings and get the sql to select the columns
set column_names_verified [list]

foreach column_name $column_names {

    if {[db_0or1row address_book_get_pretty_names "
    select pretty_name, 
           extra_select 
    from   address_book_viewable_columns 
    where  column_name= :column_name"]} {
	## column name in cookie exists in column names db
	append page_content [display_table_heading $column_name $pretty_name $desc $order_last]

	if ![empty_string_p $extra_select] {
	    ## the column name is an alias to the address book columns
	    lappend column_names_verified "$extra_select as $column_name"
	} else {
	    lappend column_names_verified $column_name
	}
    }
}

if {$scope_administrator_p} {
    ## the editting fields
    append page_content "<td colspan=2 bgcolor=navy>&nbsp;</td>"
}


append page_content "</tr>"

## start querying for rows user_id, address_book_id, 

set bgcolor [list "white" "silver"]
set count   0

db_foreach address_book_get_index_rows "
    select user_id, 
           address_book_id, 
           [join $column_names_verified {, }]
    from   address_book 
    where  [ad_scope_sql] 
    order by $order_by_sql
" {

    append page_content "<tr bgcolor=[lindex $bgcolor [expr $count % 2]]>"
    incr count
   
    append page_content "
    <td>
    <a href=record?[export_url_scope_vars address_book_id]>View</a>
    </td>"

    foreach column $column_names_verified {
        # if alias, extract the actual name
	regexp { as ([^ \n]*)$} $column match column
        append page_content "<td>[set $column]&nbsp;</td>"
    }

    if { $scope_administrator_p } {
	append page_content "
	<td><a href=record-edit?[export_url_scope_vars address_book_id]>edit</a></td>
	<td><a href=record-delete?[export_url_scope_vars address_book_id]>delete</a></td>
	"
    }

    append page_content "</tr>"

} if_no_rows {
    append page_content "
    There are currently no addresses.
    <p>
    <a href=record-add?[export_url_scope_vars]>Add a Record</a>
    </p>
    "
}

append page_content "</table><p>\n\n"

if { $scope_administrator_p } {
    append page_content "
    <p><a href=record-add?[export_url_scope_vars]>Add a Record</a> | 
    <a href=birthdays?[export_url_scope_vars]>View all birthdays</a> | 
    <a href=change-prefs?[export_url_scope_vars]>Change Viewing Preferences</a></p>
    "
}

append page_content "
</center>

[ad_scope_footer]"

doc_return  200 text/html $page_content

