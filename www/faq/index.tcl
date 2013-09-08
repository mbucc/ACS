# /faq/index.tcl
#

ad_page_contract {
    Purpose: shows a list of user-viewable FAQs.
    
    @author dh@arsdigita.com
    @creation-date December, 1999
    @cvs-id index.tcl,v 3.6.2.8 2000/09/22 01:37:42 kevin Exp

    Note: if page is accessed through /groups pages then group_id and
    group_vars_set are already set up in the environment by the
    ug_serve_section. group_vars_set contains group related variables
    (group_id, group_name, group_short_name, group_admin_email,
    group_public_url, group_admin_url, group_public_root_url,
    group_admin_root_url, group_type_url_p, group_context_bar_list
    and group_navbar_list)
} {
    scope:optional
    group_id:integer,optional
}

ad_scope_error_check

set user_id [ad_scope_authorize $scope all group_member none]

# get the FAQs this person can see
switch $scope {
    public {
	set bind_vars [ad_tcl_vars_to_ns_set user_id]
	if { $user_id == 0 } {
	    # user not logged in, so show only public faqs

	    set sql {
		select distinct faq_name, 
		faq_id, 
		scope as faq_scope, 
		faqs.group_id as faq_group_id
		from faqs
		where faqs.scope = 'public' 
		order by faq_name }
	} else {
	    # user is logged in, so show public faqs and the faqs of the groups user beolngs to
	    # for group faqs, make sure that they are enabled (in content sections table)

	    set sql "
	    select distinct faq_name, faq_id, faqs.scope as faq_scope, faqs.group_id as faq_group_id
	    from faqs, user_group_map
	    where faqs.scope = 'public' 
	    or (ad_group_member_p ( :user_id, faqs.group_id ) = 't'
                and faqs.scope='group')
	    order by faq_name"
	}
    }
    group {
	# for group faqs, make sure that they are enabled (in content sections table)
	set sql "
	select distinct faq_name, faq_id, faqs.scope as faq_scope, faqs.group_id as faq_group_id
	from faqs, content_sections cs
	where faqs.scope = 'group' and faqs.group_id = :group_id
	order by faq_name"
    }
}
    
set faq_count 0
set faq_list ""

db_foreach faq_faqname_get $sql {
    incr faq_count

    if { $faq_scope == "public" } {
	set link_url "one?[export_url_vars faq_id]"
    } else {
	set short_name [db_string faq_groupname_get "select short_name
                                          from user_groups
                                          where group_id = :faq_group_id"]
	set link_url "/[ad_parameter GroupsDirectory ug]/[ad_urlencode $short_name]/faq/one?[export_url_vars faq_id]"
    }

    append faq_list "<li><a href=$link_url>$faq_name</a>\n"
}

if { $faq_count == 0 } {    
    set faq_list "There are currently no FAQs available for you to see."
}
db_release_unused_handles


set header_content "[ad_scope_header "FAQs"]
[ad_scope_page_title "FAQs"]
[ad_scope_context_bar_ws_or_index "FAQs"]
<hr>"


set page_content "

$header_content

[ad_scope_navbar]
<p>
<ul>
$faq_list
</ul>
<p>
[ad_scope_footer]"



doc_return  200 text/html $page_content
