# /www/ticket/admin/domain-edit.tcl
ad_page_contract {
    Create or modify a ticket domain
    
    @param domain_id the ID of the domain we are modifying or copying
    @param ascopy are we making a copy of an existing domain
    @param return_url where to send to user when we are done

    @author original author unknown
    @author Kevin Scaldeferri (kevin@caltech.edu)
    @cvs-id domain-edit.tcl,v 3.4.6.5 2000/09/22 01:39:25 kevin Exp
} { 
    {domain_id:integer ""} 
    {ascopy ""} 
    {return_url "/ticket/"}
}

# -----------------------------------------------------------------------------

set user_id [ad_verify_and_get_user_id]

if { ![empty_string_p $domain_id] } {
    page_validation {
	if {! [db_0or1row domain_info "
	select td.*,
	       u.email, 
	       u.first_names || ' ' || u.last_name as user_name, 
	       ug.group_name as orig_owning_group
	from   ticket_domains td, users u, user_groups ug
	where  domain_id = :domain_id 
	and    u.user_id = td.created_by 
	and    td.group_id = ug.group_id" ]} {
            error "Domain ID \"$msg_id\" not found."
        }
    }

    if {[empty_string_p $ascopy]} {
        set is old
    } else { 
        set is ascopy
        set copy_domain_id $domain_id
        set what(ascopy) "New feature area as a copy of $title_long"
        set title {}
        set title_long {}
        set description {}
    }
} else { 
    set is new
    set copy_domain_id {}
    set title ""
    set title_long ""
    set created_by $user_id
    set group_id ""
    set description ""
    set notify_admin_p ""
    set notify_comment_p ""
    set notify_status_p ""
    set message_template ""
    # defaults for new
    set public_p t
}

if {$is != "old"} { 
    # get a new domain_id and 
    db_1row new_domain_info "
    select ticket_domain_id_sequence.nextval as domain_id,
           u.email, 
           u.first_names || ' ' || u.last_name as user_name
    from   users u
    where  user_id = :user_id" 
}

set what(new) "Create Feature Area"
set what(old) "Edit Feature Area"
set submit(new) "Create"
set submit(ascopy) "Create Copy"
set submit(old) "Update"

append page_content "
[ad_header "Ticket Tracker $what($is)"]

<h2>Ticket Tracker: $what($is)</h2>

[ad_context_bar_ws_or_index [list /ticket/ "Ticket Tracker"]  \
	[list /ticket/admin/ Administration] $what($is)]
<hr>

<blockquote>
  <h3>Feature area $title_long</h3>Created by: [ticket_user_display $user_name $email $created_by admin]<br>"

if {[info exists orig_owning_group]} { 
    append page_content "Owning group: 
    <a href=\"/admin/ug/group?group_id=$group_id\">$orig_owning_group</a> 
    &nbsp;(<a href=\"domain-change-group?domain_id=$domain_id&domain_name=[ns_urlencode $title_long]\">change</a>)"  
}

append page_content "
<form action=\"domain-edit-2\" method=post>
[export_form_vars domain_id is]

<table border=0>
  <tr>
    <th align=left>Short Title:</th>
    <td><input type=text name=title size=20 [export_form_value title]></td>
  </tr>
  <tr>
    <th align=left>Long Title:</th>
    <td><input type=text name=title_long size=60 [export_form_value title_long]></td>
  </tr>
"

if [empty_string_p $group_id] { 
    set setone {{{} {-- Set a group --}}}
} else { 
    set setone {}
}

# We would like to see the type of group because
# there could be many groups in the system, some
# with the same name.

# We define the type of group as:
# a) The name of the parent group if there is one
# b) The group_type otherwise

set select [ad_db_select_widget -default $group_id -option_list $setone \
	domain_groups \
"select 
  nvl(ugp.group_name, ug.group_type) || ': ' || ug.group_name as group_name,  
  ug.group_id 
from user_groups ug, user_groups ugp
where ug.parent_group_id = ugp.group_id (+)
  and ug.approved_p = 't'
order by lower(nvl(ugp.group_name, ug.group_type)), lower(group_name)
" group_id]

append page_content "
  <tr>
    <th align=left>Owning Group:</th>
    <td>$select</td>
  </tr>
  <tr>
    <th valign=top align=left>Description:</th>
    <td><textarea name=description rows=4 cols=60 wrap=soft>$description</textarea></td>
  </tr>
  <tr>
     <th valign=top align=left>Message<br>template:</th>
     <td><textarea name=message_template rows=8 cols=60 wrap=hard>$message_template</textarea></td>
  </tr>
[bool_table_prompt -span 2 {Tickets publicly visible?} public_p $public_p]
[bool_table_prompt -span 2 {Notify Admin on create?} notify_admin_p $notify_admin_p]
[bool_table_prompt -span 2 {Notify on comment add?} notify_comment_p $notify_comment_p]
[bool_table_prompt -span 2 {Notify on status change?} notify_status_p $notify_status_p]
"

if {$is != "old"} {
    set select [ad_db_select_widget -default $copy_domain_id \
	    -option_list {{{} {--Optional--}}} copy_domain_info "
    select title_long, domain_id 
    from   ticket_domains tp 
    where  exists (select 1 from ticket_domain_project_map td 
                   where td.domain_id = tp.domain_id) 
    order by upper(title_long)" copy_domain_id]

    append page_content "  <tr>
    <th align=left>Assign to same<br>projects as:</th>
    <td>$select</td>
  </tr>\n"
}

append page_content "
</table> 
  <blockquote>
  <input type=submit value=\"$submit($is)\">
  </blockquote>
  </blockquote>
  </form>

[ad_footer]"

doc_return  200 text/html $page_content