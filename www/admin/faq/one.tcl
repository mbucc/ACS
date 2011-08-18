
# admin/faq/one.tcl
#
#   displays the properties of one FAQ
#
#   Allowed actions on existing FAQs - change associated group
#                                    - change / add maintainer
#                                    - change privacy policy
#                                    - delete FAQ
#
# by dh@arsidigita.com, created on Dec 20, 1999
#
# $Id: one.tcl,v 3.0.4.1 2000/03/17 17:42:47 aure Exp $
#-----------------------------------------------------------

ad_page_variables {faq_id}

set db [ns_db gethandle]

# get the faq_name and scope--------------------------------
set selection [ns_db 0or1row $db "
select f.faq_name, 
       f.scope,
       f.group_id as current_group_id,
       count(fqa.entry_id) as number_of_questions
from   faqs f, faq_q_and_a fqa
where  f.faq_id = $faq_id 
and    f.faq_id = fqa.faq_id(+)
group by f.faq_name, f.scope, f.group_id "]

if { [empty_string_p $selection] } {
    # this FAQ doesn't exist
    ns_return 200 text/html "
    [ad_admin_header "No FAQ"]
    
    <h2>No FAQ</h2>

    [ad_admin_context_bar [list index "FAQs"] "No FAQ"]
    

    <hr>
    
    Sorry, but the FAQ you requested does not exist.

    <p>

    [ad_admin_footer]"
    
    return
} else {
    # the FAQ exists
    set_variables_after_query
}

set_variables_after_query


if { $scope == "public" } {
    set admin_url_string "/faq/admin/one?[export_url_vars faq_id scope]"
    set userpage_url_string "/faq/one?[export_url_vars faq_id scope]"
} else {
    set short_name [database_to_tcl_string $db "select short_name
                                                from user_groups
                                                where group_id = $current_group_id"]    
    set admin_url_string "/[ad_parameter GroupsDirectory ug]/[ad_parameter GroupsAdminDirectory ug]/[ad_urlencode $short_name]/faq/one?[export_url_vars faq_id scope]&group_id=$current_group_id"
    set userpage_url_string "/[ad_parameter GroupsDirectory ug]/[ad_urlencode $short_name]/faq/one?[export_url_vars faq_id scope]&group_id=$current_group_id" 
}


# make and option list of all the group names --------------
# highlighting the current group ---------------------------

set selection [ns_db select $db "
select group_name, 
       group_id 
from  user_groups
where user_groups.group_type <> 'administration' 
order by group_name "]

set group_option_list "<select name=group_id> \n"
append group_option_list "<option value=\"\" [expr {""==$current_group_id?"selected":""}]>No group \n"

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    append group_option_list "<option value=$group_id [expr {$group_id==$current_group_id?"selected":""}]>$group_name \n"
}
append group_option_list "</select>"

#------------------------------------------------------------

ns_db releasehandle $db

# -- serve the page ---------------------------------

ns_return 200 text/html "
[ad_admin_header "FAQ: $faq_name"]

<h2>FAQ: $faq_name</h2>

[ad_admin_context_bar [list index "FAQs"] $faq_name]

<hr>

<table>
<tr>
 <td align=right> Maintainer Page:</td>
 <td> <a href=$admin_url_string>$admin_url_string</a></td>
</tr>
<tr>
 <td align=right>User Page:</td>
 <td> <a href=$userpage_url_string>$userpage_url_string</a></td>
</tr>
<tr>
 <td align=right> Number of questions:</td>
 <td> $number_of_questions </td>
</tr>
</table>

<h4>Properties</h4>

<block_quote>

<form action=faq-edit-2.tcl method=post>

[export_form_vars faq_id]

<table>
<tr>
 <td align=right>FAQ Name:</td>
 <td><input type=text name=faq_name value=\"[philg_quote_double_quotes $faq_name]\"></td>
</tr>

<tr>
 <td align=right>Group:</td>
 <td>$group_option_list</td>
</tr>
<tr>
 <td>&nbsp;</td>
 <td><input type=submit value=\"Update Properties\"></td>
</tr>
</table>
</form>

</block_quote>


<P>

<h4>Extreme Actions</h4>
<ul>

<li><a href=faq-delete?faq_id=$faq_id>Delete the FAQ</a>

</ul>


[ad_admin_footer]"





