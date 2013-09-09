# www/calendar/admin/categories.tcl
ad_page_contract {
    Lists categories

    Number of queries: 2

    @author Philip Greenspun (philg@mit.edu)
    @author Sarah Ahmed (ahmeds@arsdigita.com)
    @creation-date 1998-11-18
    @cvs-id categories.tcl,v 3.2.2.5 2000/09/22 01:37:06 kevin Exp
    
} {
    {scope public}
    {user_id:naturalnum ""}
    {group_id:naturalnum ""}
    {on_what_id:naturalnum ""}
    {on_which_group:naturalnum ""}
}

# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)
# maybe contact_info_only, maybe order_by


ad_scope_error_check

ad_scope_authorize $scope admin group_admin none


set page_content "
[ad_scope_admin_header "Calendar categories"]
[ad_scope_admin_page_title "Categories"]
[ad_scope_admin_context_bar [list "index.tcl?[export_url_scope_vars]" "Calendar"] "Categories"]

<hr>

<ul>

"



set enabled_headline_shown_p 0
set disabled_headline_shown_p 0

db_foreach categories "
select category_id, category, enabled_p 
from calendar_categories
where [ad_scope_sql]
order by enabled_p desc


"  {
    
    if { $enabled_headline_shown_p == 0 && $enabled_p == "t" } {
	append page_content "<h4>Categories in which users can post</h4>
	<ul>"
	set enabled_headline_shown_p 1
    } 

    if { $disabled_headline_shown_p == 0 && $enabled_p == "f" } {
	append page_content "</ul>
	<h4>Disabled Categories</h4>
	<ul>"
	set disabled_headline_shown_p 1
    } 
    
    append page_content "<li><a href=\"category-one?[export_url_scope_vars]&category_id=[ns_urlencode $category_id]\">$category</a>\n"
    
} if_no_rows {
    
    append page_content "no event categories are currently defined"
}





set next_category_id [db_nextval "calendar_category_id_sequence"]

db_release_unused_handles



append page_content "
<P>
<li><form method=post action=category-new>
[export_form_scope_vars next_category_id]
Add a category:
<input type=text name=category_new>
<input type=submit name=submit value=\"Add\">
</form>
</ul>

<p>e.g. <i>Workshops, June Conference Series,</i> etc.</p>
</ul>
[ad_scope_admin_footer]
"
 
doc_return  200 text/html $page_content

## END FILE categories.tcl
