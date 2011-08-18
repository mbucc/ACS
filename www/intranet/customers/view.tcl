# $Id: view.tcl,v 3.2.2.2 2000/03/17 08:22:54 mbryzek Exp $
# File: /www/intranet/customers/view.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# View all info regarding one customer
#

set current_user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set_form_variables
# group_id

set return_url [ad_partner_url_with_query]

set db [ns_db gethandle]

# Admins and Employees can administer customers
set user_admin_p [im_is_user_site_wide_or_intranet_admin $db $current_user_id]
if { $user_admin_p == 0 } {
    set user_admin_p [im_user_is_employee_p $db $current_user_id]
}

# set user_admin_p [im_can_user_administer_group $db $group_id $current_user_id]

if { ! $user_admin_p } {
    # We let employees have full administrative control
    set user_admin_p [im_user_is_employee_p $db $current_user_id]
}

if { $user_admin_p > 0 } {
    # Set up all the admin stuff here in an array
    set admin(projects) "  <p><li><a href=../projects/ae.tcl?customer_id=$group_id>Add a project</a>"
    set admin(basic_info) "  <p><li> <a href=ae.tcl?[export_url_vars group_id return_url]>Edit this information</a>"
    set admin(contact_info) "<p><li><a href=/address-book/record-add.tcl?scope=group&[export_url_vars group_id return_url]>Add a contact</a>"
} else {
    set admin(projects) ""
    set admin(basic_info) ""
    set admin(contact_info) ""
}
	

set selection [ns_db 1row $db \
	"select g.group_name, g.registration_date, c.note, g.short_name,
                ab.first_names||' '||ab.last_name as primary_contact_name, primary_contact_id,
                nvl(im_cust_status_from_id(customer_status_id),'&lt;-- not specified --&gt;') as customer_status
	   from user_groups g, im_customers c, address_book ab
	  where g.group_id=$group_id
	    and g.group_id=c.group_id
            and c.primary_contact_id=ab.address_book_id(+)"]

set_variables_after_query

set page_title $group_name
set context_bar [ad_context_bar [list "/" Home] [list ../index.tcl "Intranet"] [list index.tcl "Customers"] "One customer"]

set left_column "
<ul> 
  <li> Status: $customer_status
  <li> Added on [util_AnsiDatetoPrettyDate $registration_date]
"

set primary_contact_text ""
set limit_to_users_in_group_id [im_employee_group_id]
if { [empty_string_p $primary_contact_id] } {
    if { $user_admin_p } {
	set primary_contact_text "<a href=primary-contact.tcl?[export_url_vars group_id limit_to_users_in_group_id]>Add primary contact</a>\n"
    } else {
	set primary_contact_text "<i>none</i>"
    }
} else {
    append primary_contact_text "<a href=/address-book/record.tcl?address_book_id=$primary_contact_id&[export_url_vars group_id]&scope=group>$primary_contact_name</a>"
    if { $user_admin_p } {
	append primary_contact_text "    (<a href=primary-contact.tcl?[export_url_vars group_id limit_to_users_in_group_id]>change</a> |
	<a href=primary-contact-delete.tcl?[export_url_vars group_id return_url]>remove</a>)\n"
    }
}

append left_column "
  <li> Primary contact: $primary_contact_text
  <li> Group short name: $short_name
"


if { ![empty_string_p $note] } {
    append left_column "  <li> Notes: <font size=-1>$note</font>\n"
}


append left_column "
$admin(basic_info)
</ul>
"

# Let's create the list of active projects

set selection [ns_db select $db \
	"select user_group_name_from_id(group_id) as project_name,
                group_id as project_id, level, im_project_ticket_project_id(group_id) as ticket_project_id
           from im_projects p
          where customer_id=$group_id
     connect by prior group_id=parent_id
     start with parent_id is null"]

set projects_html ""
set current_level 1
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { $level > $current_level } {
	append projects_html "  <ul>\n"
	incr current_level
    } elseif { $level < $current_level } {
	append projects_html "  </ul>\n"
	set current_level [expr $current_level - 1]
    }	
    if { $ticket_project_id == 0 } {
	set ticket_link "(<a href=../projects/ticket-edit.tcl?group_id=$project_id&[export_url_vars return_url]>create ticket tracker</a>)"
    } else {
	set ticket_link "(<a href=/ticket/index.tcl?project_id=$ticket_project_id>ticket tracker</a>)"
    }
    append projects_html "  <li><a href=../projects/view.tcl?group_id=$project_id>$project_name</a> - $ticket_link\n"
}
if { [exists_and_not_null level] && $level < $current_level } {
    append projects_html "  </ul>\n"
}	
if { [empty_string_p $projects_html] } {
    set projects_html "  <li><i>None</i>\n"
}


append left_column "<b>Contact correspondence and strategy reviews:</b>\n"

if { [exists_and_not_null show_all_correspondance_comments] } {
    append left_column [ad_general_comments_summary_sorted $db $group_id im_customers $group_name]
} else {
    set url_for_more "[im_url_stub]/projects/view.tcl?show_all_correspondance_comments=1&[export_ns_set_vars url [list show_all_correspondance_comments]]"
    append left_column [ad_general_comments_summary_sorted $db $group_id im_customers $group_name 5 $url_for_more]
}

append left_column "
<ul>
<p><a href=\"/general-comments/comment-add.tcl?group_id=$group_id&scope=group&on_which_table=im_customers&on_what_id=$group_id&item=[ns_urlencode $group_name]&module=intranet&[export_url_vars return_url]\">Add a correspondance</a>
</ul>
"


# Print out the address book
set contact_info ""
set selection [ns_db select $db \
	"select * 
           from address_book 
          where group_id=$group_id
       order by lower(last_name)"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append contact_info "<p><li>[address_book_record_display $selection "f"]\n"
    if { $user_admin_p > 0 } {
	append contact_info "
<br>
\[<a href=/address-book/record-edit.tcl?scope=group&[export_url_vars group_id address_book_id return_url]>edit</a> | 
<a href=/address-book/record-delete.tcl?scope=group&[export_url_vars group_id address_book_id return_url]>delete</a>\]
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
set since_when [database_to_tcl_string $db "select sysdate - 30 from dual"]
set news [news_new_stuff $db $since_when 0 "web_display" 1 0 $group_id]
if { [empty_string_p $news] } {
    set news "  <li> <em>none</em>\n"
}
set news_dir [im_groups_url -db $db -group_id $group_id -section news]

if { [ad_parameter ApprovalPolicy news] == "open"} {
    append news "\n<li><a href=\"$news_dir/post-new.tcl?scope=group&[export_url_vars return_url]\">post an item</a>\n"
} elseif { [ad_parameter ApprovalPolicy news] == "wait"} {
    append news "\n<li><a href=\"$news_dir/post-new.tcl?scope=group&[export_url_vars return_url]\">suggest an item</a>\n"
}
append news " | <a href=$news_dir/index.tcl?scope=group&archive_p=1>archives</a>\n"


## BBoards are not currently supported
if { [ad_parameter BBoardEnabledP intranet 0] } {
    ## Links to associated bboards
    set bboard_string ""
    set selection [ns_db select $db \
	    "select topic, topic_id, presentation_type
               from bboard_topics
              where group_id=$group_id"]
    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	set link [bboard_complete_backlink $topic_id $topic $presentation_type]
	regsub {href="} $link {href="/bboard/} link
	append bboard_string "  <li> $link\n"
    }
    if { [empty_string_p $bboard_string] } {
	set bboard_string "  <li> <em>none</em>\n"
    }
    append bboard_string " <li> <a href=bboard-ae.tcl?[export_url_vars group_id]>Create a new discussion group</a>\n"
} else {
    set bboard_string ""
}

## Links to associated sections (things we don't know where else to put!)
set sections "  <li><a href=/file-storage/group.tcl?[export_url_vars group_id]>File Storage</a>\n"

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
[im_table_with_title "[ad_parameter SystemName] Employees" "<ul>[im_users_in_group $db $group_id $current_user_id "Spam employees working with $group_name" $user_admin_p $return_url [im_employee_group_id]]</ul>"]
[im_table_with_title "Customer Employees" "<ul>[im_users_in_group $db $group_id $current_user_id "Spam users who work for $group_name" $user_admin_p $return_url [im_customer_group_id] [im_employee_group_id]]</ul>"]
  </td>
</tr>
</table>

"

ns_db releasehandle $db
ns_return 200 text/html [ad_partner_return_template]