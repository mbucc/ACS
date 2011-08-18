# $Id: project-edit-2.tcl,v 3.0.4.1 2000/04/28 15:11:37 carsten Exp $
ad_page_variables {
    project_id is title title_long version 
    start_date group_id public_p 
    description code_set default_mode {copy_project_id {}}
    message_template {end_date {}}
    {domain_id_list -multiple-list} {domain_id_list {}}
    {return_url {}}
}

set db [ns_db gethandle]
set user_id [ad_get_user_id]

if {[empty_string_p $title]} { 
    ad_return_complaint 1 "<li>You must provide a title"
    return
}
if {![empty_string_p $domain_id_list] && ![empty_string_p $copy_project_id]} { 
    ad_return_complaint 1 "<li>You may either inherit domains from another project or assign domains.  Not both."
    return
}
if {[empty_string_p $group_id]} { 
    ad_return_complaint 1 "<li>You must assign a group"
    return
}

if {[empty_string_p $title_long]} { 
    set title_long $title
}

if {![empty_string_p $domain_id_list]} { 
    set copy_domains_sql [list "delete ticket_domain_project_map where project_id = $project_id and domain_id not in ([join $domain_id_list {,}])"]
    lappend copy_domains_sql "insert into ticket_domain_project_map (project_id, domain_id) 
  select $project_id, domain_id from ticket_domains td where td.domain_id in ([join $domain_id_list {,}])
    and not exists (select 1 from ticket_domain_project_map tgpm where project_id = $project_id and td.domain_id = tgpm.domain_id)
"
} elseif {![empty_string_p $copy_project_id]} {
    set copy_domains_sql [list "
 insert into ticket_domain_project_map(project_id, domain_id) 
  select $project_id as project_id, tg.domain_id
  from ticket_domain_project_map tg 
  where tg.project_id = $copy_project_id 
    and not exists (
      select 1 
      from ticket_domain_project_map tg2 
      where tg2.project_id = $project_id 
        and tg2.domain_id = tg.domain_id)"]
} else { 
    set copy_domains_sql {}
}

if {$is != "old"} { 
    # a new or ascopy project
    util_dbq {title title_long version start_date end_date
        public_p description code_set default_mode message_template}
    set sql "
 insert into ticket_projects ( 
  project_id, title, title_long, version, created_by, start_date, 
  end_date, group_id, public_p, description, code_set, default_mode, message_template
 ) values (
  $project_id, $DBQtitle, $DBQtitle_long, $DBQversion, $user_id, $DBQstart_date,
  $DBQend_date, $group_id, $DBQpublic_p, $DBQdescription, $DBQcode_set, $DBQdefault_mode,
  $DBQmessage_template
 )"
} else { 
    # an old project...do an update
    util_dbq {title title_long version start_date end_date
        public_p description code_set default_mode message_template}
    set sql "
 update ticket_projects set 
  title=$DBQtitle, title_long=$DBQtitle_long, version=$DBQversion,
  start_date=$DBQstart_date, end_date=$DBQend_date, group_id=$group_id,
  public_p=$DBQpublic_p, description=$DBQdescription, code_set=$DBQcode_set,
  default_mode=$DBQdefault_mode, message_template=$DBQmessage_template
 where project_id = $project_id"
}    

with_transaction $db {
    ns_db dml $db $sql
    foreach copy_domains $copy_domains_sql { 
        ns_db dml $db $copy_domains
    } 
} {
    ad_return_complaint 1 "<li>Here was the bad news from the database:
 <pre>$errmsg</pre>$copy_domains_sql"
    return
}

if {[empty_string_p $return_url]} { 
    ad_returnredirect "project-edit.tcl?project_id=$project_id"
} else { 
    ad_returnredirect "$return_url"
}


    
