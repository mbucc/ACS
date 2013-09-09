# /admin/links/delete-2.tcl

ad_page_contract {
    Step 2 in deleting a link from a page

    @param page_id The ID of the page to delete from
    @param url The link to delete
    @deletion_reason The reason behind the deletion (null, "spam", "dupe", or "other")

    @author Original Author Unknown
    @creation-date Original Date Unknown
    @cvs-id delete-2.tcl,v 3.3.2.7 2000/09/22 01:35:29 kevin Exp
} {
    page_id:notnull,naturalnum
    url:notnull
    deletion_reason:optional
}

set admin_id [ad_verify_and_get_user_id]

if { $admin_id == 0 } {
    ad_returnredirect "/register/"
    return
}

# we know who the administrator is



set offending_user_id [db_string select_user_id "select user_id from links
where page_id = :page_id
and url = :url"]

db_dml delete_link "delete from links 
where page_id = :page_id
and url = :url"

db_1row select_page_info "select url_stub, nvl(page_title, url_stub) as page_title
from static_pages
where static_pages.page_id = :page_id"

set page_content "[ad_admin_header "Link Deleted"]
    
<h2>Link Deleted</h2>

<hr>

The link to $url has been deleted from the database.

"

if { [mv_enabled_p] && [info exists $deletion_reason] && ![empty_string_p $deletion_reason] && $deletion_reason != "other" } {
    # this is a naughty user; let's assess a charge
    if { $deletion_reason == "spam" } {
	set amount [mv_parameter LinkSpamRate]
	set charge_type "link_spam"
	set charge_comment "SPAM: Added a link from $url_stub to $url."
    } else {
	# assume it was some kind of mistake
	set amount [mv_parameter LinkDupeRate]
	set charge_type "link_dupe"
	set charge_comment "Dupe/Mistake: Added a link from $url_stub to $url."
    }
    if { $amount > 0 } {
	db_dml charge_user "insert into  users_charges (user_id, admin_id, charge_type, amount, currency, entry_date, charge_comment)
values
(:offending_user_id, :admin_id, :charge_type, :amount, '[mv_parameter Currency]', sysdate, :charge_comment)"
        ns_write "<p>
Charged user <a href=\"/admin/users/one?user_id=$offending_user_id\">$offending_user_id</a> ([db_string select_user_info "select first_names || ' ' || last_name from users where user_id = $offending_user_id"]) [mv_parameter Currency] $amount, under category $charge_type."
    }
}

db_release_unused_handles

append page_content "

<p>

You can visit <a href=\"$url_stub\">$url_stub</a> if you'd like to see
how the links look now.

[ad_admin_footer]
"

doc_return  200 text/html $page_content