# /faq/index.tcl
#
# dh@arsdigita.com, December, 1999
#
# Purpose: shows a list of user-viewable FAQs.
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)
#
# $Id: index.tcl,v 3.4.2.3 2000/03/16 04:23:06 dh Exp $

set_the_usual_form_variables 0
# maybe scope, maybe scope related variables (group_id)

ad_scope_error_check

set db_pool [ns_db gethandle [philg_server_default_pool] 2]
set db  [ lindex $db_pool 0]
set db2 [ lindex $db_pool 1]

set user_id [ad_scope_authorize $db $scope all group_member none]

# get the FAQs this person can see
switch $scope {
    public {
	if { $user_id==0 } {
	    # user not logged in, so show only public faqs
	    
	    set selection [ns_db select $db "
	    select distinct faq_name, faq_id, scope as faq_scope, faqs.group_id as faq_group_id
	    from faqs
	    where faqs.scope = 'public' 
	    order by faq_name"]
	} else {
	    # user is logged in, so show public faqs and the faqs of the groups user beolngs to
	    # for group faqs, make sure that they are enabled (in content sections table)
	    set selection [ns_db select $db "
	    select distinct faq_name, faq_id, faqs.scope as faq_scope, faqs.group_id as faq_group_id
	    from faqs, user_group_map
	    where faqs.scope = 'public' 
	    or (    ad_group_member_p ( $user_id, faqs.group_id ) = 't'
                and faqs.scope='group' )
	    order by faq_name"]
	}
    }
    group {
	# for group faqs, make sure that they are enabled (in content sections table)
	set selection [ns_db select $db "
	select distinct faq_name, faq_id , faqs.scope as faq_scope, faqs.group_id as faq_group_id
	from faqs, content_sections cs
	where faqs.scope = 'group' and faqs.group_id=$group_id
	order by faq_name"]
    }
}
    
set faq_count 0
set faq_list ""

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    incr faq_count

    if { $faq_scope == "public" } {
	set link_url "one?[export_url_scope_vars faq_id]"
    } else {
	set short_name [database_to_tcl_string $db2 "select short_name
                                                    from user_groups
                                                     where group_id = $faq_group_id"]  
	set link_url "/[ad_parameter GroupsDirectory ug]/[ad_urlencode $short_name]/faq/one?[export_url_scope_vars faq_id]&scope=$faq_scope&group_id=$faq_group_id"
    }

    append faq_list "<li><a href=$link_url>$faq_name</a>\n"
}

if { $faq_count == 0 } {    
    set faq_list "There are currently no FAQs available for you to see."
}

set header_content "[ad_scope_header "FAQs" $db]
[ad_scope_page_title "FAQs" $db]
[ad_scope_context_bar_ws_or_index "FAQs"]
<hr>
"

ns_db releasehandle $db2
ns_db releasehandle $db

# --serve the page--------------------------------

ns_return 200 text/html "

$header_content

[ad_scope_navbar]
<p>
<ul>
$faq_list
</ul>
<p>
[ad_scope_footer]"






