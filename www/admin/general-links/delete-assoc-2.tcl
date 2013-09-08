# File: /admin/general-links/delete-assoc-2.tcl

ad_page_contract {
    Step 2 of 2 in deleting a link association

    @param map_id The ID of the link association to delete
    @param return_url Where to go when finished deleting

    @author Tzu-Mainn Chen (tzumainn@arsdigita.com)
    @creation-date 2/01/2000
    @cvs-id delete-assoc-2.tcl,v 3.2.2.5 2000/07/21 03:57:21 ron Exp
} {
    map_id:notnull,naturalnum
    {return_url ""}
}

#--------------------------------------------------------

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set user_id [ad_get_user_id]

db_transaction { 

            ### No audits (yet) - Tzu-Mainn Chen
            # insert into the audit table
            # db_dml link_assoc_audit "insert into general_comments_audit
            #   (comment_id, user_id, ip_address, audit_entry_time, modified_date, content)
            #   select comment_id, user_id, '[ns_conn peeraddr]', sysdate, modified_date, content from general_comments where comment_id = :comment_id"

            set link_id [db_string select_link_id "select link_id from site_wide_link_map where map_id = :map_id"]

            db_dml delete_assoc "delete from site_wide_link_map where map_id = :map_id"
} on_error {

	# there was some other error with the link deletion
	ad_return_error "Error deleting link" "We couldn't update your link. Here is what the database returned:
<p>
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>
"
return
}

db_release_unused_handles

if {[empty_string_p $return_url]} {
    set return_url "view-associations?link_id=$link_id"
}

ad_returnredirect $return_url

