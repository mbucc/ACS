# /faq/admin/index.tcl
# 
# gives a list of FAQs that this user_id may edit
# if the user is allowed to create/delete a FAQ - that option is given
# to him here.
#
# dh@arsdigita.com, December 1999
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)
#
# $Id: index.tcl,v 3.0.4.5 2000/03/16 04:21:15 dh Exp $

set_the_usual_form_variables 0
# maybe scope, maybe scope related variables (group_id)

ad_scope_error_check

# this page will show all the faqs associated with the particular group

set db [ns_db gethandle]
# this pages should be used for administration of group faqs only
# public pages can be administered at the /faq/admin by the site wide administrator
set user_id [ad_scope_authorize $db $scope admin group_admin none]

# just show the list of the faqs that group administrator of the group 
# identified by group_id can administer
set selection [ns_db select $db "
select distinct faq_name, faq_id 
from   faqs
where  [ad_scope_sql faqs]
order by faq_name"]

set avail_faq_count 0
set avail_faq_list "You may maintain the following FAQs
<ul>\n"
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    incr avail_faq_count
    append avail_faq_list "<li><a href=one?[export_url_scope_vars faq_id]>$faq_name</a>\n"
}
append avail_faq_list "</ul>\n"

if { $avail_faq_count == 0} {
    set avail_faq_list "<p> There are no FAQs in the database right now."
}

if {[info exists scope]&& $scope=="group"} {
    set context_bar "[ad_scope_admin_context_bar  "FAQ Admin"]"
} else {
    set context_bar "[ad_scope_context_bar_ws  \
	    [list "../index?[export_url_scope_vars]" "FAQs"] "Admin"]"
}

set header_content "
[ad_scope_admin_header "Admin" $db]
[ad_scope_admin_page_title "FAQs Admin" $db]"

# release the database handle

ns_db releasehandle $db

# -- serve the page ----------------------
ns_return 200 text/html "

$header_content

$context_bar

<hr>
<blockquote>
$avail_faq_list
<p>

<li><a href=faq-add>Add</a> a new FAQ.
<P>
</blockquote>
[ad_scope_admin_footer]"













