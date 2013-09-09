# www/portals/admin/add-manager.tcl

ad_page_contract {
    standard ACS prompt for email or name of proposed administrator 

    @author aure@arsdigita.com 
    @author dh@arsdigita.com
    @creation-date 10/8/1999
    @param group_id
    @cvs-id add-manager.tcl,v 3.3.2.5 2000/09/22 01:39:02 kevin Exp
} {
    group_id:notnull,naturalnum
}

# -----------------------------------
# verify user
set user_id [ad_verify_and_get_user_id]

set group_name [portal_group_name $group_id]
portal_check_administrator_maybe_redirect $user_id
# -----------------------------------

# set variables for user-search.tcl  
set custom_title "Add Portal Manager for $group_name"
set passthrough [list group_id]

# set the target for user-search.tcl in a dynamic so that this page
# can be moved to any server
regsub "manager" [ns_conn url] "manager-2" target

# ------------------------------------
# serve the page
set page_content "
[portal_admin_header $custom_title]

[ad_context_bar [list /portals/ "Portals"] [list index "Administration"] "Add Manager"]
<hr>

<form action=/user-search method=post> 
[export_form_vars target passthrough group_id custom_title]

Enter either the last name or email of the proposed manager:
<p>
<table> 
<tr>
    <td align=right>Last name:</td>
    <td><input type=text name=last_name size=25></td>
</tr>
<tr>
    <td align=right>or Email:</td>
    <td><input type=text name=email size=25></td>
</tr>
<tr>
    <td></td>
    <td><input type=submit value=\"Search\"></td>
</tr>
</table>

</form>

[portal_admin_footer]"
 
doc_return  200 text/html $page_content 










