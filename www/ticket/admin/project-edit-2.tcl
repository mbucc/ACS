# /www/ticket/admin/project-edit-2.tcl
ad_page_contract {
    Process the information to modify/create a ticket project.

    @param project_id the ID for the project
    @param is what function we are using.  One of <code>new</code>,
           <code>old</code> or <code>ascopy</code>.
    @param title the title of the project
    @param title_long a long version
    @param version a version string for the project
    @param start_date starting date for the project
    @param group_id the group associated with the project
    @param public_p is this a publicly accessible project (t/f)
    @param description description of the project
    @param code_set which set of ticket codes is being used
    @param default_mode mode in which this project operates
    @param copy_project_id if we are copying, the source project
    @param message_template a template for ticket reports
    @param end_date ending date for the project
    @param domain_id_list a list of domains for this project
    @param return_url where to go when we are done

    @author Jeff Davis (davis@arsdigita.com) ?
    @author Kevin Scaldeferri (kevin@caltech.edu)
    @creation-date ? 3.4 modifications 8 July 2000
    @cvs-id project-edit-2.tcl,v 3.3.2.7 2000/07/27 22:43:43 tony Exp
} {
    project_id:integer 
    is
    title:trim,notnull
    title_long:trim
    version:trim 
    start_date:trim,notnull
    group_id:integer,notnull
    public_p 
    description
    code_set:notnull
    default_mode:notnull
    {copy_project_id:integer {}}
    message_template
    {end_date {}}
    {domain_id_list:multiple,integer [list]}
    {return_url {}}
}

# -----------------------------------------------------------------------------

set user_id [ad_verify_and_get_user_id]

page_validation {
    if {[llength $domain_id_list] != 0 && ![empty_string_p $copy_project_id]} { 
	error "You may either inherit domains from another project or assign domains.  Not both."
    }

    if {[llength $domain_id_list] == 0 && [empty_string_p $copy_project_id]} { 
	error "You must define at least one feature area in order to book tickets in the project."
    }
    
    if {[string length $title] > 30 } {
	error "Short title can't be longer than 30 characters."
    }
}    
    
if {[empty_string_p $title_long]} { 
    set title_long $title
}

for {set i 0} {$i < [llength $domain_id_list]} {incr i} {
    set domain_id_$i [lindex $domain_id_list $i]
    lappend bind_var_list ":domain_id_$i"
}

if {![empty_string_p $domain_id_list]} { 
    set copy_domains_sql [list "
    delete ticket_domain_project_map 
    where  project_id = :project_id 
    and    domain_id not in ([join $bind_var_list ","])" "
    insert into ticket_domain_project_map 
     (project_id, domain_id) 
    select  :project_id, domain_id 
      from  ticket_domains td 
      where td.domain_id in ([join $bind_var_list ","])
      and   not exists (select 1 from ticket_domain_project_map tgpm 
                        where  project_id = :project_id 
                        and    td.domain_id = tgpm.domain_id)"]

} elseif {![empty_string_p $copy_project_id]} {
    set copy_domains_sql [list "
    insert into ticket_domain_project_map
     (project_id, domain_id) 
    select  :project_id as project_id, tg.domain_id
      from  ticket_domain_project_map tg 
      where tg.project_id = $copy_project_id 
      and   not exists (select 1 from ticket_domain_project_map tg2 
                        where  tg2.project_id = :project_id 
                        and    tg2.domain_id = tg.domain_id)"]
} else { 
    set copy_domains_sql {}
}

if {$is != "old"} { 
    # a new or ascopy project
    set sql "
    insert into ticket_projects 
    (project_id, title, title_long, version, created_by, start_date, 
     end_date, group_id, public_p, description, code_set, default_mode, 
     message_template) 
    values 
    (:project_id, :title, :title_long, :version, :user_id, :start_date,
     :end_date, :group_id, :public_p, :description, :code_set, :default_mode,
     :message_template)"
} else { 
    # an old project...do an update
    set sql "
    update ticket_projects 
    set   title = :title, 
    	  title_long = :title_long, 
    	  version = :version,
    	  start_date = :start_date, 
    	  end_date = :end_date, 
    	  group_id = :group_id,
    	  public_p = :public_p, 
    	  description = :description, 
    	  code_set = :code_set,
    	  default_mode = :default_mode, 
    	  message_template = :message_template
    where project_id = :project_id"
}    

db_transaction {
    db_dml project_insert_or_update $sql 
    foreach copy_domains $copy_domains_sql { 
        db_dml project_domains_insert $copy_domains
    } 
} on_error {
    ad_return_complaint 1 "Most likely you entered a name that is already used.
    <p>Here was the bad news from the database:
 <pre>$errmsg</pre>$copy_domains_sql"
    return
}

if {[empty_string_p $return_url]} { 
    ad_returnredirect "project-edit.tcl?project_id=$project_id"
} else { 
    ad_returnredirect "$return_url"
}

    


