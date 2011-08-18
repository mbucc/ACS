# domain-add-user-3.tcl
# Create various qmail files and insert information into data model for creating a user.
# Written by jsc@arsdigita.com.

ad_page_variables {username short_name user_id_from_search}

set db [ns_db gethandle]


with_transaction $db {
    ns_db dml $db "insert into wm_email_user_map (email_user_name, domain, user_id)
 values ('$QQusername', '$QQshort_name', $user_id_from_search)"

    # If this is the first email account for this user, create his INBOX.
    if { [database_to_tcl_string $db "select count(*) 
from wm_mailboxes
where creation_user = $user_id_from_search
 and name = 'INBOX'"] == 0 } {
	ns_db dml $db "insert into wm_mailboxes (mailbox_id, name, creation_user, creation_date, uid_validity)
 values (wm_mailbox_id_sequence.nextval, 'INBOX', $user_id_from_search, sysdate, 0)"
    }

    # Create alias file for this user.
    set alias_fp [open "[ad_parameter AliasDirectory webmail "/home/nsadmin/qmail/alias"]/.qmail-$short_name-$username" w 0644]
    puts $alias_fp [ad_parameter QueueDirectory webmail "/home/nsadmin/qmail/queue/"]
    close $alias_fp
} {
    set full_domain_name [database_to_tcl_string $db "select full_domain_name
from wm_domains
where short_name = '$QQshort_name'"]
    ad_return_error "Error Creating Email Account" "An error occured while 
trying to create the email account for $username@$full_domain_name:
<pre>
$errmsg
</pre>
"
    return
}


ad_returnredirect "domain-one.tcl?[export_url_vars short_name]"
