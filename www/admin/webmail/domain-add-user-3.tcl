# domain-add-user-3.tcl

ad_page_contract {
    Create various qmail files and insert information into data model
    for creating a user.

    @author Jin Choi (jsc@arsdigita.com)
    @creation-date 2000-02-23
    @cvs-id domain-add-user-3.tcl,v 1.4.2.6 2000/09/08 21:08:24 erik Exp
} {
    username:notnull
    short_name:notnull
    user_id_from_search:integer,notnull
}

if [db_0or1row check_duplicate_entry {select email_user_name as tmp 
                                      from wm_email_user_map
                                      where email_user_name=:username
                                      and domain=:short_name
                                      and user_id=:user_id_from_search}] {
    ad_return_complaint 1 " <li> The entry already exists in the database."
    return
}

db_transaction {
    db_dml add_user {
	insert into wm_email_user_map (email_user_name, domain, user_id)
	values (:username, :short_name, :user_id_from_search)
    }

    # If this is the first email account for this user, create his INBOX.
    if { [db_string inbox_count "select count(*) 
from wm_mailboxes
where creation_user = :user_id_from_search
 and name = 'INBOX'"] == 0 } {
	db_dml add_inbox {
	    insert into wm_mailboxes (mailbox_id, name, creation_user, creation_date, uid_validity)
	    values (wm_mailbox_id_sequence.nextval, 'INBOX', :user_id_from_search, sysdate, 0)
	}
    }

    # Create alias file for this user. 
    # qmail requires we substitute '.' in aliases with ':'
    regsub {\.} $username ":" alias_name
    set alias_fp [open "[ad_parameter AliasDirectory webmail "/home/nsadmin/qmail/alias"]/.qmail-$short_name-$alias_name" w 0644]
    puts $alias_fp [ad_parameter QueueDirectory webmail "/home/nsadmin/qmail/queue/"]
    close $alias_fp
} on_error {
    db_1row get_full_domain_name { select full_domain_name
                                   from wm_domains
                                   where short_name = :short_name }
    ad_return_error "Error Creating Email Account" "An error occured while 
trying to create the email account for $username@$full_domain_name:
<pre>
$errmsg
</pre>
"
    return
}


ad_returnredirect "domain-one.tcl?[export_url_vars short_name]"
