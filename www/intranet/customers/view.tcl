# /www/intranet/customers/view.tcl

ad_page_contract {
    View all info regarding one customer

    @param group_id the group_id of this customer

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000

    @cvs-id view.tcl,v 3.20.2.20 2000/09/22 01:38:28 kevin Exp

} {
    group_id:integer
    show_all_correspondance_comments:integer,optional
}

set current_user_id [ad_maybe_redirect_for_registration]

set return_url [im_url_with_query]


# We need to know if the user belongs to the group to be able to do things
# through scoping. If not, we add an intermedia page to ask the user if s/he
# wants to join the group before continuing
set user_belongs_to_group_p [ad_user_group_member $group_id $current_user_id]

# Admins and Employees can administer customers
set user_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
if { $user_admin_p == 0 } {
    set user_admin_p [im_user_is_employee_p $current_user_id]
}

# set user_admin_p [im_can_user_administer_group $group_id $current_user_id]

if { ! $user_admin_p } {
    # We let employees have full administrative control
    set user_admin_p [im_user_is_employee_p $current_user_id]
}

if { $user_admin_p > 0 } {
    # Set up all the admin stuff here in an array
    set admin(projects) "  <p><li><a href=../projects/ae?customer_id=$group_id>Add a project</a>"
    set admin(basic_info) "  <p><li> <a href=ae?[export_url_vars group_id return_url]>Edit this information</a>"
    set admin(contact_info) "<p><li><a href=[im_group_scope_url $group_id $return_url "/address-book/record-add" $user_belongs_to_group_p]>Add a contact</a>"
} else {
    set admin(projects) ""
    set admin(basic_info) ""
    set admin(contact_info) ""
}

db_1row customer_get_info \
	"select g.group_name, g.registration_date, c.note, g.short_name, c.billable_p,
                ab.first_names||' '||ab.last_name as primary_contact_name, primary_contact_id,
                nvl(im_category_from_id(customer_status_id),'&lt;-- not specified --&gt;') as customer_status,
                nvl(customer_type,'&lt;-- not specified --&gt;') as customer_type,
                nvl(im_category_from_id(annual_revenue),'&lt;-- not specified --&gt;') as annual_revenue,
                nvl(referral_source,'&lt;-- not specified --&gt;') as referral_source,
                to_char(start_date,'Month DD, YYYY') as start_date, 
                contract_value, site_concept, 
                m.first_names||' '||m.last_name as manager, m.user_id as manager_id
	   from user_groups g, im_customers c, address_book ab, im_customer_types, users m
	  where g.group_id=:group_id
	    and g.group_id=c.group_id
	    and c.manager = m.user_id(+)
            and c.customer_type_id = im_customer_types.customer_type_id (+)
            and c.primary_contact_id=ab.address_book_id(+)" 

set page_title $group_name
set context_bar [ad_context_bar_ws [list ./ "Customers"] "One customer"]

set left_column "
<ul> 
  <li> Status: $customer_status
  <li> Customer Type: $customer_type
  <li> Client Service Manager: <a href=[im_url_stub]/users/view?user_id=$manager_id>$manager</a>
  <li> Added on [util_AnsiDatetoPrettyDate $registration_date]
  <li> Referral source: $referral_source
  <li> Billable? [util_PrettyBoolean $billable_p]
"

set primary_contact_text ""
set limit_to_users_in_group_id [im_employee_group_id]
if { [empty_string_p $primary_contact_id] } {
    if { $user_admin_p } {
	set primary_contact_text "<a href=primary-contact?[export_url_vars group_id limit_to_users_in_group_id]>Add primary contact</a>\n"
    } else {
	set primary_contact_text "<i>none</i>"
    }
} else {
    append primary_contact_text "<a href=/address-book/record?address_book_id=$primary_contact_id&[export_url_vars group_id]&scope=group>$primary_contact_name</a>"
    if { $user_admin_p } {
	append primary_contact_text "    (<a href=primary-contact?[export_url_vars group_id limit_to_users_in_group_id]>change</a> |
	<a href=primary-contact-delete?[export_url_vars group_id return_url]>remove</a>)\n"
    }
}

append left_column "
  <li> Primary contact: $primary_contact_text
[im_email_aliases $short_name]
"

if { [ad_parameter EnabledP ischecker 0] } {
    append left_column "  <li> Machines:  <ul> \n"
    foreach machine [is_machine_list_for_group $group_id] {
	set hostname [lindex $machine 1]
	set machine_id [lindex $machine 0]
	append left_column "<li><a href=/ischecker/machine-view?[export_url_vars machine_id]>$hostname</a><font size=-1> (<a href=/ischecker/group-machine-map-delete?[export_url_vars group_id machine_id]&return_url=[ns_urlencode [ns_conn url]?[ns_conn query]]>delete</a>)</font>"
    }
    append left_column "
<li><a href=/ischecker/group-machine-map?[export_url_vars group_id]&return_url=[ns_urlencode [ns_conn url]?[ns_conn query]]&pretty_name=[ns_urlencode $group_name]>Add a machine</a>
</ul>
  <li> Annual Revenue: $annual_revenue
"
}

if { ![empty_string_p $start_date] } {
    append left_column "<li> Start Date: $start_date"
}
if { ![empty_string_p $contract_value] } {
    append left_column "<li> Contract Value: \$[util_commify_number $contract_value] K"
}
if { ![empty_string_p $site_concept] } {
    append left_column "<li> Site Concept: $site_concept"
}
if { ![empty_string_p $note] } {
    append left_column "  <li> Notes: <font size=-1>$note</font>\n"
}


append left_column "
$admin(basic_info)
</ul>
"

# Let's create the list of active projects

set sql "select user_group_name_from_id(group_id) as project_name,
                group_id as project_id, level, im_project_ticket_project_id(group_id) as ticket_project_id
           from im_projects p
          where customer_id=:group_id
     connect by prior group_id=parent_id
     start with parent_id is null"

set projects_html ""
set current_level 1
db_foreach customer_list_active_projects $sql  {
    if { $level > $current_level } {
	append projects_html "  <ul>\n"
	incr current_level
    } elseif { $level < $current_level } {
	append projects_html "  </ul>\n"
	set current_level [expr $current_level - 1]
    }	
    if { $ticket_project_id == 0 } {
	set ticket_link "(<a href=../projects/ticket-edit?group_id=$project_id&[export_url_vars return_url]>create ticket tracker</a>)"
    } else {
	set ticket_link "(<a href=/ticket/index?project_id=$ticket_project_id>ticket tracker</a>)"
    }
    append projects_html "  <li><a href=../projects/view?group_id=$project_id>$project_name</a> - $ticket_link\n"
}
if { [exists_and_not_null level] && $level < $current_level } {
    append projects_html "  </ul>\n"
}	
if { [empty_string_p $projects_html] } {
    set projects_html "  <li><i>None</i>\n"
}


append left_column "<b>Contact correspondence and strategy reviews:</b>\n"

if { [exists_and_not_null show_all_correspondance_comments] } {
    append left_column [ad_general_comments_summary_sorted $group_id user_groups $group_name]
} else {
    set url_for_more "[im_url_stub]/customers/view?show_all_correspondance_comments=1&[export_ns_set_vars url [list show_all_correspondance_comments]]"
    append left_column [ad_general_comments_summary_sorted $group_id user_groups $group_name 5 $url_for_more]
}

append left_column "
<ul>
<p><a href=\"/general-comments/comment-add?group_id=$group_id&scope=group&on_which_table=user_groups&on_what_id=$group_id&item=[ns_urlencode $group_name]&module=intranet&[export_url_vars return_url]\">Add a correspondence</a>
</ul>
"


# Print out the address book
set contact_info ""
set address_book_sql "select ab.address_book_id, ab.first_names, ab.last_name, ab.email, ab.email2,
                ab.line1, ab.line2, ab.city, ab.country, ab.usps_abbrev, ab.zip_code, ab.birthmonth, ab.birthyear,
                ab.phone_home, ab.phone_work, ab.phone_cell, ab.phone_other, ab.notes 
           from address_book ab
          where ab.group_id=:group_id
       order by lower(ab.last_name)" 
db_foreach address_book_info $address_book_sql  {
    set address_book_info [ad_tcl_vars_to_ns_set address_book_id first_names last_name email email2 line1 line2 city country birthmonth birthyear phone_home phone_work phone_cell phone_other notes]
    
    append contact_info "<p><li>[address_book_display_one_row]\n"
    if { $user_admin_p > 0 } {
	append contact_info "
<br>
\[<a href=[im_group_scope_url $group_id $return_url "/address-book/record-edit?[export_url_vars address_book_id]" $user_belongs_to_group_p]>edit</a> | 
<a href=[im_group_scope_url $group_id $return_url "/address-book/record-delete?[export_url_vars address_book_id]" $user_belongs_to_group_p]>delete</a>\]
"
    }
} 

if { [empty_string_p $contact_info] } {
    set contact_info "  <li> <i>None</i>\n"
}

append left_column "
<b>Contact Information</b>
<ul>
$contact_info
$admin(contact_info)
</ul>
"

## News specific to this customer
set since_when [db_string sysdate_from_dual "select sysdate - 30 from dual"]
set news [news_new_stuff $since_when 0 "web_display" 1 0 $group_id]
if { [empty_string_p $news] } {
    set news "  <li> <em>none</em>\n"
}
set news_dir [im_groups_url -group_id $group_id -section news]

if { [ad_parameter ApprovalPolicy news] == "open"} {
    append news "\n<li><a href=\"$news_dir/post-new?[export_url_vars return_url]\">post an item</a>\n"
} elseif { [ad_parameter ApprovalPolicy news] == "wait"} {
    append news "\n<li><a href=\"$news_dir/post-new?[export_url_vars return_url]\">suggest an item</a>\n"
}
append news " | <a href=$news_dir/index?archive_p=1>archives</a>\n"


if { ![ad_parameter BBoardEnabledP intranet 0] } {
    set bboard_string ""
} else {
    ## Links to associated bboards
    ## first pull out bboards at the customer level
    set bboard_customer ""
    set sql "select topic, topic_id, presentation_type
               from bboard_topics
              where group_id=:group_id
              order by lower(topic)"

    db_foreach customer_list_bboard_topics $sql  {
	set link [bboard_complete_backlink $topic_id $topic $presentation_type]
	regsub {href="} $link {href="/bboard/} link
	append bboard_customer "  <li> $link\n"
    }
    
    # Now look at any bboards for any of this customer's projects
    set bboard_projects ""
    set sql "select topic, topic_id, presentation_type
               from bboard_topics
              where group_id in (select group_id 
                                   from im_projects 
                                  where customer_id=:group_id)
              order by lower(topic)"

    db_foreach customer_list_project_bboards $sql  {
	set link [bboard_complete_backlink $topic_id $topic $presentation_type]
	regsub {href="} $link {href="/bboard/} link
	append bboard_projects "  <li> $link\n"
    }
    
    set bboard_string "
[util_decode $bboard_customer "" "<em>none</em>" "$bboard_customer"]
<li> <a href=bboard-ae?[export_url_vars group_id]>Create a new discussion group</a>
"
 
    if { ![empty_string_p $bboard_projects] } {
	append bboard_string "<p><b>Project Discussion Groups</b>$bboard_projects\n"
    } 
}

## Links to associated sections (things we don't know where else to put!)
set sections "  <li><a href=/file-storage/private-one-group?[export_url_vars group_id]>File Storage</a>\n"

set page_body "
<table width=100% cellpadding=0 cellspacing=2 border=0>
<tr>
  <td valign=top>
$left_column
  </td>
  <td valign=top>
[im_table_with_title "Customer News" "<ul>$news</ul>"]
[util_decode $bboard_string "" "" [im_table_with_title "Discussion Groups" "<ul>$bboard_string</ul>"]]
[im_table_with_title "Sections" "<ul>$sections</ul>"]
[im_table_with_title "Projects" "<ul>$projects_html\n$admin(projects)</ul>"]
[im_table_with_title "[ad_parameter SystemName] Employees" "<ul>[im_users_in_group $group_id $current_user_id "Spam employees working with $group_name" $user_admin_p $return_url [im_employee_group_id]]</ul>"]
[im_table_with_title "Customer Employees" "<ul>[im_users_in_group $group_id $current_user_id "Spam users who work for $group_name" $user_admin_p $return_url [im_customer_group_id] [im_employee_group_id]]</ul>"]
  </td>
</tr>
</table>

"


doc_return  200 text/html [im_return_template]
