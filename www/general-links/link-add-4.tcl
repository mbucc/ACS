# File: /general-links/link-add-4.tcl

ad_page_contract {
    Step 4 of 4 in adding link and its association.
    
    @param on_which_table the table that the link is associated with
    @param on_what_id the ID column of on_which_table
    @param item the item
    @param module the module
    @param return_url the url to return to
    @param link_id the generated ID of the link
    @param association_id the ID of the associated item
    @param link_title the title of the link
    @param url the URL of the link
    @param link_description a description of the link
    @param category_id_list a list of the categories the link belongs to
    @param rating is the rating 

    @Creation-date  2/01/2000
    @Author: tzumainn@arsdigita.com 
    @cvs-id link-add-4.tcl,v 3.4.2.6 2001/01/10 21:03:10 khy Exp
} {
    on_which_table:notnull
    on_what_id:notnull
    item:notnull
    {module ""} 
    return_url:notnull
    link_id:notnull,naturalnum,verify
    association_id:notnull,naturalnum,verify
    link_title:notnull
    url:notnull
    rating:notnull,naturalnum
    category_id_list:multiple 
    {link_description ""}
}


if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}


set category_id_list_hack [lindex $category_id_list 0]

# user has input something, so continue on

# assign necessary data for insert
set user_id [ad_maybe_redirect_for_registration]

set originating_ip [ns_conn peeraddr]



# Get the default approval policy for the site
set approval_policy [ad_parameter DefaultLinkApprovalPolicy]

if {$approval_policy == "open"} {
    set approved_p "t"
} else {
     set approved_p ""
}

if [catch {
    db_transaction {
    ad_general_link_add $link_id $url $link_title $link_description $user_id $originating_ip $approved_p
    ad_general_link_map_add $association_id $link_id $on_which_table $on_what_id $item $user_id $originating_ip $approved_p
    if {$category_id_list_hack != "{}"} {
	ad_categorize_row -which_table "general_links" -what_id $link_id -category_id_list $category_id_list_hack -one_line_item_desc $link_title
    }
    ad_general_link_check $link_id
    db_dml insert_rating "insert into general_link_user_ratings (user_id, link_id, rating)
    values
    (:user_id, :link_id, :rating)
    "
    }
} errmsg] {
    # Oracle choked on the insert
    db_dml abort "abort transaction"
    if { [db_string select_link_exists "select count(*) from general_links where link_id = :link_id"] == 0 } {
	# there was an error with link insert other than a duplication

	ad_return_error "Error in inserting link" "We were unable to insert your link in the database.  Here is the error that was returned:
	<p>
	<blockquote>
	<pre>
	$errmsg
	</pre>
	</blockquote>"
        return
     } elseif { [db_string select_association_exists "select count(*) from site_wide_link_map where map_id = :association_id"] == 0 } { 
	 # there was an error with link association insert other than a duplication

	ad_return_error "Error in inserting link association" "We were unable to insert your link association in the database.  Here is the error that was returned:
	<p>
	<blockquote>
	<pre>
	$errmsg
	</pre>
	</blockquote>"
        return
     } else {
	 ad_returnredirect $return_url
     }
}

db_release_unused_handles

ad_returnredirect $return_url




