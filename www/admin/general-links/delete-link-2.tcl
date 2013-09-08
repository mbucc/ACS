# File: /admin/general-links/delete-link-2.tcl

ad_page_contract {
    Step 2 of 2 in deleting a link and everything associated with it

    @param link_id The ID of the link to delete
    @param return_url Where to go when done deleting

    @author Tzu-Mainn Chen (tzumainn@arsdigita.com)
    @creation-date 2/01/2000
    @cvs-id delete-link-2.tcl,v 3.1.6.6 2000/07/24 18:25:16 ryanlee Exp
} {
    link_id:notnull,naturalnum
    {return_url "index"}
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
            # db_dml audit_link_delete "insert into general_comments_audit
            #   (comment_id, user_id, ip_address, audit_entry_time, modified_date, content)
            #   select comment_id, user_id, '[ns_conn peeraddr]', sysdate, modified_date, content from general_comments where comment_id = :comment_id"

            db_dml delete_from_category_map "delete from site_wide_category_map where on_which_table = 'general_links' and on_what_id = :link_id"

            db_dml delete_from_user_ratings "delete from general_link_user_ratings where link_id = :link_id"
            db_dml delete_from_link_map "delete from site_wide_link_map where link_id = :link_id"
            db_dml delete_from_general_links "delete from general_links where link_id=$link_id"

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

ad_returnredirect $return_url

