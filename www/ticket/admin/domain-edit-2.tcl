# $Id: domain-edit-2.tcl,v 3.1.2.1 2000/04/28 15:11:36 carsten Exp $
ad_page_variables {
    domain_id is title title_long 
    group_id public_p 
    description 
    message_template 
    notify_admin_p
    notify_comment_p
    notify_status_p
    {copy_domain_id {}}
    {return_url {}}
}

set db [ns_db gethandle]
set user_id [ad_get_user_id]

if {[empty_string_p $title]} { 
    ad_return_complaint 1 "<li>You must provide a title for the feature area."
    return
}
if {[empty_string_p $group_id]} { 
    ad_return_complaint 1 "<li>You must assign a group to the feature area."
    return
}

if {[empty_string_p $title_long]} { 
    set title_long $title
}

set copy_projects_sql "
 insert into ticket_domain_project_map(project_id, domain_id)
  select tg.project_id, $domain_id as domain_id
  from ticket_domain_project_map tg 
  where tg.domain_id = $copy_domain_id 
    and not exists (
      select 1 
      from ticket_domain_project_map tg2 
      where tg2.project_id = tg.project_id
        and tg2.domain_id = $domain_id)"

if {$is != "old"} { 
    # a new or ascopy project
    util_dbq {title title_long public_p description message_template
        notify_admin_p notify_comment_p notify_status_p}
    set sql "
 insert into ticket_domains ( 
  domain_id, title, title_long, created_by, group_id, public_p, description, 
     notify_admin_p, notify_comment_p, notify_status_p, message_template
 ) values (
  $domain_id, $DBQtitle, $DBQtitle_long, $user_id, $group_id, $DBQpublic_p, $DBQdescription,
     $DBQnotify_admin_p, $DBQnotify_comment_p, $DBQnotify_status_p, $DBQmessage_template
 )"

    with_transaction $db {
        ns_db dml $db $sql

        if {![empty_string_p $copy_domain_id]} { 
            ns_db dml $db $copy_projects_sql
        }
    } {
        ad_return_complaint 1 "<li>Here was the bad news from the database:
 <pre>$errmsg</pre>"
        return
    }
} else { 
    # an old project...do an update
    util_dbq {title title_long public_p description message_template
        notify_admin_p notify_comment_p notify_status_p}
    set sql "
 update ticket_domains set 
  title=$DBQtitle, title_long=$DBQtitle_long, group_id=$group_id,
  public_p=$DBQpublic_p, description=$DBQdescription, message_template=$DBQmessage_template,
     notify_admin_p = $DBQnotify_admin_p, notify_comment_p = $DBQnotify_comment_p, notify_status_p = $DBQnotify_status_p
 where domain_id = $domain_id"

    with_transaction $db {
        ns_db dml $db $sql

        if {![empty_string_p $copy_domain_id]} { 
            ns_db dml $db $copy_projects_sql
        } 
    } { 
        ad_return_complaint 1 "<li>Here was the bad news from the database:
 <pre>$errmsg</pre>"
        return
    }
}    



if {[empty_string_p $return_url]} { 
    ad_returnredirect "index.tcl?view=domain&domain_id=$domain_id"
} else { 
    ad_returnredirect "$return_url"
}
