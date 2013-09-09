# File: /admin/general-links/edit-link-2.tcl

ad_page_contract {
    Step 2 of 2 in editing a link

    @param link_id The ID of the link to update
    @param link_title The new link title
    @param url The new URL
    @param link_description The new descrpition
    @param approved_p The new approval status
    @param return_url Where we go after this
    @param category_id_list Use in the ad_categorize_row widget

    @author Tzu-Mainn Chen (tzumainn@arsdigita.com)
    @creation-date 2/01/2000
    @cvs-id edit-link-2.tcl,v 3.3.2.6 2000/07/24 18:25:16 ryanlee Exp
} {
    link_id:notnull,naturalnum
    link_title:notnull
    url:notnull
    link_description:notnull,html
    approved_p:notnull
    {return_url "index"}
    {category_id_list:multiple ""}
}

#--------------------------------------------------------

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set admin_id [ad_maybe_redirect_for_registration]

db_transaction {

    #### No audits, yet - Tzu-Mainn Chen
    # insert into the audit table
    #            db_dml link_audit "insert into general_comments_audit
    #(comment_id, user_id, ip_address, audit_entry_time, modified_date, content)
    # select comment_id, :admin_id, '[ns_conn peeraddr]', sysdate, modified_date, content from general_comments where comment_id = :comment_id"
    
    set current_approval_status [db_string select_current_approval_status "select approved_p from general_links where link_id = :link_id"]
    
    if { $current_approval_status != $approved_p } {
	db_dml update_approved_p "update general_links set approved_p = logical_negation(approved_p), last_approval_change = sysdate where link_id = :link_id"
    }
    
    db_dml update_link "update general_links
    set url = :url,
    link_title = :link_title,
    link_description = :link_description,
    last_modified = sysdate,
    last_modifying_user = :admin_id
    where link_id = :link_id"

    if { $category_id_list != "{}"} {
	ad_categorize_row -which_table "general_links" -what_id $link_id -category_id_list $category_id_list -one_line_item_desc $link_title
    }

    ad_general_link_check $link_id

} on_error {

    # there was some other error with the link update
    ad_return_error "Error updating link" "We couldn't update your link. Here is what the database returned:
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


