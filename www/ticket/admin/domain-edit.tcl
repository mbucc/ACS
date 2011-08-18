# $Id: domain-edit.tcl,v 3.2 2000/03/08 13:13:46 davis Exp $
proc bool_table_prompt {prompt name value} { 
    set html "<tr><th align=left>$prompt</th><td>"
    if {$value == "t"} {
        append html "<input type=radio name=$name value=t CHECKED> Yes
  <input type=radio name=$name value=f> No</td>\n</tr>\n\n"
    } else {  
        append html "<input type=radio name=$name value=t> Yes
  <input type=radio name=$name value=f CHECKED> No</td></tr>\n\n"
    }
    return $html 
}
    
ad_page_variables { {domain_id {}} {ascopy {}} {return_url {/ticket/}}}

    
set db [ns_db gethandle]
set user_id [ad_get_user_id]

if { ![empty_string_p $domain_id] } {
    if {[regexp {^[ ]*[0-9]+[ ]*$} $domain_id]} {    
        set selection [ns_db 1row $db "select tp.*,
            u.email, 
            u.first_names || ' ' || u.last_name as user_name
          from ticket_domains tp, users u
          where domain_id = $domain_id and u.user_id = tp.created_by"]
        if {[empty_string_p $selection]} {
            ad_return_complaint 1 "<li>Domain ID \"$msg_id\" not found."
            return
        }
        set_variables_after_query
    } else {
        ad_return_complaint 1 "<li>Domain ID \"$msg_id\" is invalid."
        return
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
    # ugh.
    set selection [ns_db select $db "select tp.* from ticket_domains tp where 0 = 1"]
    ns_db getrow $db $selection
    set_variables_after_query
    # defaults for new
    set public_p t
}

if {$is != "old"} { 
    # get a new domain_id and stuff
    set selection [ns_db 1row $db "select 
            ticket_domain_id_sequence.nextval as domain_id,
            to_char(sysdate,'YYYY-MM-DD') as start_date,
            u.email, 
            u.first_names || ' ' || u.last_name as user_name
       from users u
       where user_id = $user_id"]
    set_variables_after_query
}

ReturnHeaders
set what(new) "Create Feature Area"
set what(old) "Edit Feature Area"
set submit(new) "Create"
set submit(ascopy) "Create Copy"
set submit(old) "Update"

ns_write "[ad_header "Ticket Tracker $what($is)"]
 <h1>Ticket Tracker: $what($is)</h1>
 [ad_context_bar_ws_or_index [list $return_url "Ticket Tracker"]  $what($is)]
<hr>"

ns_write "Feature area $title_long created by: $user_name (<a href=\"mailto:$email\">$email</a>)<br>
 <form action=\"domain-edit-2.tcl\" method=post><table border=0>
 [export_form_vars domain_id is]"
ns_write "<tr><th align=left>Short Title:</th><td><input type=text name=title size=20 [export_form_value title]></td></tr>\n"
ns_write "<tr><th align=left>Long Title:</th><td><input type=text name=title_long size=60 [export_form_value title_long]></td></tr>\n"
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

set select [ad_db_select_widget -default $group_id -option_list $setone $db "select nvl(user_group_parent.group_name, user_groups.group_type) || ': ' || user_groups.group_name as group_name,  
user_groups.group_id 
from user_groups, user_groups user_group_parent
where user_groups.parent_group_id = user_group_parent.group_id (+)
and user_groups.approved_p = 't'
order by lower(nvl(user_group_parent.group_name, user_groups.group_type)), 
lower(group_name)
" group_id]
ns_write "<tr><th align=left>Owning Group:</th><td>$select</td></tr>\n"
ns_write "<tr><th valign=top align=left>Description:</th><td><textarea name=description rows=4 cols=60 wrap=soft>$description</textarea></td></tr>\n"
ns_write "<tr><th valign=top align=left>Message<br>template:</th><td><textarea name=message_template rows=8 cols=60 wrap=hard>$message_template</textarea></td></tr>\n"
ns_write [bool_table_prompt {Public?} public_p $public_p]
ns_write [bool_table_prompt {Notify Admin<br>on create?} notify_admin_p $notify_admin_p]
ns_write [bool_table_prompt {Notify on<br>comment add?} notify_comment_p $notify_comment_p]
ns_write [bool_table_prompt {Notify on<br>status change?} notify_status_p $notify_status_p]

if {$is != "old"} {
    set select [ad_db_select_widget -default $copy_domain_id -option_list {{{} {--Optional--}}} $db "select title_long, domain_id from ticket_domains tp where exists (select 1 from ticket_domain_project_map td where td.domain_id = tp.domain_id) order by upper(title_long)" copy_domain_id]
    ns_write "<tr><th align=left>Assign to same<br>projects as:</th><td>$select</td></tr>\n"
}
ns_write "</table> 
  <blockquote>
  <input type=submit value=\"$submit($is)\">
  </blockquote>
  </form><p>"

ns_write "[ad_footer]"

