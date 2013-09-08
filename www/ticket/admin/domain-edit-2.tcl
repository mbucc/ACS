# /www/ticket/admin/domain-edit-2.tcl
ad_page_contract {
    Process the new information for a domain
    
    @param domain_id the ID for the domain
    @param is what function we are using.  One of <code>new</code>,
           <code>old</code> or <code>ascopy</code>.
    @param title the title of the domain
    @param title_long a long version
    @param group_id the group associated with the domain
    @param public_p is this a publicly accessible domain (t/f)
    @param description description of the domain
    @param copy_domain_id if we are copying, the source domain
    @param message_template a template for ticket reports
    @param return_url where to go when we are done
    @param notify_admin_p notify the owner on ticket creation?
    @param notify_comment_p notify the owner of comments?
    @param notify_status_p notify the owner of change of status?

    @author original author unknown
    @author Kevin Scaldeferri (kevin@caltech.edu)
    @cvs-id domain-edit-2.tcl,v 3.3.2.4 2000/07/21 04:04:39 ron Exp
} {
    domain_id:integer,notnull 
    is:notnull 
    title:trim,notnull 
    title_long:trim,notnull
    group_id:integer,notnull 
    public_p 
    description 
    message_template 
    notify_admin_p
    notify_comment_p
    notify_status_p
    {copy_domain_id ""}
    {return_url ""}
}

# -----------------------------------------------------------------------------

set user_id [ad_verify_and_get_user_id]

set copy_projects_sql "
insert into ticket_domain_project_map
(project_id, domain_id)
select  tg.project_id, 
        :domain_id as domain_id
  from  ticket_domain_project_map tg 
  where tg.domain_id = :copy_domain_id 
  and   not exists (select 1 from ticket_domain_project_map tg2 
                    where  tg2.project_id = tg.project_id
                    and    tg2.domain_id = :domain_id)"

if {$is != "old"} { 
    # a new or ascopy project
    set sql "
    insert into ticket_domains 
    (domain_id, title, title_long, created_by, group_id, public_p, 
      description, notify_admin_p, notify_comment_p, notify_status_p, 
      message_template) 
    values 
    (:domain_id, :title, :title_long, :user_id, :group_id, :public_p, 
      :description, :notify_admin_p, :notify_comment_p, :notify_status_p, 
      :message_template)"

    db_transaction {
        db_dml domain_insert $sql 

        if {![empty_string_p $copy_domain_id]} { 
            db_dml copy_project_insert $copy_projects_sql
        }
    } on_error {
        ad_return_complaint 1 "<li>Here was the bad news from the database:
 <pre>$errmsg</pre>"
        return
    }

} else { 
    # an old project...do an update
    set sql "
    update ticket_domains 
    set title = :title, 
        title_long = :title_long, 
        group_id = :group_id,
        public_p = :public_p, 
        description = :description, 
        message_template = :message_template,
        notify_admin_p = :notify_admin_p, 
        notify_comment_p = :notify_comment_p, 
        notify_status_p = :notify_status_p
    where domain_id = :domain_id"

    db_transaction  {
        db_dml domain_update $sql

        if {![empty_string_p $copy_domain_id]} { 
            db_dml copy_project_insert $copy_projects_sql
        } 
    } on_error { 
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
