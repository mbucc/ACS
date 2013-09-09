# www/admin/portals/add-manager.tcl

ad_page_contract {
    standard ACS prompt for email or name of proposed super administrator 

    @author aure@arsdigita.com
    @author dh@arsdigita.com
    @creation-date 10/8/1999
    @cvs-id add-manager.tcl,v 3.3.2.7 2000/09/22 01:35:49 kevin Exp
} {
}

# get group_id
set group_id [db_string group_id "select group_id 
    from user_groups
    where group_name = 'Super Administrators'
    and group_type = 'portal_group'" -default ""]

if [empty_string_p $group_id] {
    ad_return_error "No Super Administrators group" "You need to set up a \"Super Administrators\" group (of type \"portal_group\") before you can use the system."
    return
}

set group_name [portal_group_name $group_id]

# set variables for user-search.tcl  
set custom_title "Add  $group_name"

# set the target for user-search.tcl in a dynamic so that this page
# can be moved to any server
regsub "manager" [ns_conn url] "manager-2" target

# ----------------------------------------
# serve the page



doc_return  200 text/html "[ad_admin_header "Add Administrator"]

<h2>Add Administrator</h2>

[ad_admin_context_bar [list index.tcl "Portals Admin"] "Add Administrator"]

<hr>

<form action=/user-search method=post> 
[export_form_vars target  custom_title]

Enter either the last name or email of the proposed manager:
<p>
<table> 
<tr>
    <td align=right>Email:</td>
    <td><input type=text name=email size=25></td>
</tr>
<tr>
    <td align=right>or Last name:</td>
    <td><input type=text name=last_name size=25></td>
</tr>
<tr>
    <td></td>
    <td><input type=submit value=\"Search\"></td>
</tr>
</table>

</form>

[ad_admin_footer]
"

















