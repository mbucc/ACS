# /packages/acs-core/security-init.tcl

ad_library {

    Provides methods for authorizing and identifying ACS 
    (both logged in and not) and tracking their sessions.

    @creation-date 16 Feb 2000
    @author Jon Salz [jsalz@arsdigita.com]
    @cvs-id security-init.tcl,v 1.11.2.6 2001/01/13 01:19:01 khy Exp

}

# Register the security filters (critical and high-priority).

ad_register_filter -critical t -priority 1 trace * /* ad_issue_deferred_dml

ad_filter_restricted_content_sections

# Schedule a procedure to sweep for sessions.
ad_schedule_proc -thread f [ad_parameter SessionSweepInterval "" 3600] sec_sweep_sessions

# we will bounce people out of /pvt if they don't have a cookie
ad_register_filter preauth HEAD /pvt/* ad_verify_identity
ad_register_filter preauth GET /pvt/* ad_verify_identity
ad_register_filter preauth POST /pvt/* ad_verify_identity

nsv_set ad_security request 0

# Do we want to analyze incoming URL variables for malicious SQL? With
# bind variables, the semantics of SQL statements can't be changed, so
# this is not necessary; this is left here only for those who want the
# extra layer of security.
if [ad_parameter BlockSqlUrlsP request-processor 0] {
    ad_register_filter preauth GET /* ad_block_sql_urls
    ad_register_filter preauth POST /* ad_block_sql_urls
    ad_register_filter preauth HEAD /* ad_block_sql_urls
}

# Since each TCL page calls ad_page_contract, which verifies the types
# and checks all user input for malicious variables, there is no real
# need for these filters. These are provided for those who want an
# extra layer of security.
if [ad_parameter ParanoiaInputFiltersP request-processor 0] {
    ad_set_typed_form_variable_filter /admin/calendar/item-category-change.tcl {user_id fail}
    ad_set_typed_form_variable_filter /admin/calendar/post-edit-2.tcl {user_id fail}
    ad_set_typed_form_variable_filter /admin/calendar/post-new-2.tcl {user_id fail}
    ad_set_typed_form_variable_filter /admin/calendar/post-new-3.tcl {user_id fail}
    ad_set_typed_form_variable_filter /admin/calendar/post-new-4.tcl {user_id fail}
    ad_set_typed_form_variable_filter /admin/comments/delete.tcl {user_id fail}
    ad_set_typed_form_variable_filter /admin/crm/transition-add-2.tcl {user_id fail}
    ad_set_typed_form_variable_filter /admin/crm/transition-add.tcl {user_id fail}
    ad_set_typed_form_variable_filter /admin/crm/transition-edit-2.tcl {user_id fail}
    ad_set_typed_form_variable_filter /admin/crm/transition-edit.tcl {user_id fail}
    ad_set_typed_form_variable_filter /admin/gc/delete-ad-2.tcl {user_id fail}
    ad_set_typed_form_variable_filter /admin/gc/delete-ad.tcl {user_id fail}
    ad_set_typed_form_variable_filter /admin/gc/delete-ads-from-one-user-2.tcl {user_id fail}
    ad_set_typed_form_variable_filter /admin/gc/delete-ads-from-one-user.tcl {user_id fail}
    ad_set_typed_form_variable_filter /admin/gc/edit-ad-2.tcl {user_id fail}
    ad_set_typed_form_variable_filter /admin/gc/edit-ad.tcl {user_id fail}
    ad_set_typed_form_variable_filter /admin/general-comments/edit-2.tcl {user_id fail}
    ad_set_typed_form_variable_filter /admin/general-comments/edit.tcl {user_id fail}
    ad_set_typed_form_variable_filter /admin/glossary/one.tcl {user_id fail}
    ad_set_typed_form_variable_filter /admin/glossary/term-approve.tcl {user_id fail}
    ad_set_typed_form_variable_filter /admin/glossary/term-delete.tcl {user_id fail}
    ad_set_typed_form_variable_filter /admin/glossary/term-edit-2.tcl {user_id fail}
    ad_set_typed_form_variable_filter /admin/glossary/term-edit.tcl {user_id fail}
    ad_set_typed_form_variable_filter /admin/glossary/term-new-2.tcl {user_id fail}
    ad_set_typed_form_variable_filter /admin/glossary/term-new-3.tcl {user_id fail}
    ad_set_typed_form_variable_filter /admin/links/blacklist-2.tcl {user_id fail}
    ad_set_typed_form_variable_filter /admin/links/blacklist-remove.tcl {user_id fail}
    ad_set_typed_form_variable_filter /admin/links/blacklist.tcl {user_id fail}
    ad_set_typed_form_variable_filter /admin/links/delete-2.tcl {user_id fail}
    ad_set_typed_form_variable_filter /admin/links/delete.tcl {user_id fail}
    ad_set_typed_form_variable_filter /admin/links/restore.tcl {user_id fail}
    ad_set_typed_form_variable_filter /admin/users/approve-email.tcl {user_id fail}
    ad_set_typed_form_variable_filter /admin/users/approve.tcl {user_id fail}
    ad_set_typed_form_variable_filter /admin/users/delete-2.tcl {user_id fail}
    ad_set_typed_form_variable_filter /admin/users/reject.tcl {user_id fail}
    ad_set_typed_form_variable_filter /bboard/confirm.tcl {user_id fail}
    ad_set_typed_form_variable_filter /calendar/admin/post-edit-2.tcl {user_id fail}
    ad_set_typed_form_variable_filter /calendar/admin/post-new-3.tcl {user_id fail}
    ad_set_typed_form_variable_filter /calendar/admin/post-new-4.tcl {user_id fail}
    ad_set_typed_form_variable_filter /calendar/admin/post-new.tcl {user_id fail}
    ad_set_typed_form_variable_filter /calendar/post-new-4.tcl {user_id fail}
    ad_set_typed_form_variable_filter /download/index.tcl {user_id fail}
    ad_set_typed_form_variable_filter /events/admin/activity-add-2.tcl {user_id fail}
    ad_set_typed_form_variable_filter /events/admin/activity-edit.tcl {user_id fail}
    ad_set_typed_form_variable_filter /events/admin/event-add-3.tcl {user_id fail}
    ad_set_typed_form_variable_filter /events/admin/event-edit.tcl {user_id fail}
    ad_set_typed_form_variable_filter /events/admin/event-price-ae-2.tcl {user_id fail}
    ad_set_typed_form_variable_filter /events/admin/order-history-date.tcl {user_id fail}
    ad_set_typed_form_variable_filter /events/admin/order-history-one.tcl {user_id fail}
    ad_set_typed_form_variable_filter /events/admin/order-same-person.tcl {user_id fail}
    ad_set_typed_form_variable_filter /events/admin/order-search.tcl {user_id fail}
    ad_set_typed_form_variable_filter /events/admin/organizer-add.tcl {user_id fail}
    ad_set_typed_form_variable_filter /events/admin/reg-approve-2.tcl {user_id fail}
    ad_set_typed_form_variable_filter /events/admin/reg-cancel-2.tcl {user_id fail}
    ad_set_typed_form_variable_filter /events/admin/reg-wait-list-2.tcl {user_id fail}
    ad_set_typed_form_variable_filter /events/admin/spam-selected-events-2.tcl {user_id fail}
    ad_set_typed_form_variable_filter /events/admin/venues-ae-2.tcl {user_id fail}
    ad_set_typed_form_variable_filter /events/order-cancel-2.tcl {user_id fail}
    ad_set_typed_form_variable_filter /events/order-cancel.tcl {user_id fail}
    ad_set_typed_form_variable_filter /events/order-check.tcl {user_id fail}
    ad_set_typed_form_variable_filter /events/order-one.tcl {user_id fail}
    ad_set_typed_form_variable_filter /gc/admin/delete-ad-2.tcl {user_id fail}
    ad_set_typed_form_variable_filter /gc/admin/delete-ad.tcl {user_id fail}
    ad_set_typed_form_variable_filter /gc/admin/delete-ads-from-one-user-2.tcl {user_id fail}
    ad_set_typed_form_variable_filter /gc/admin/delete-ads-from-one-user.tcl {user_id fail}
    ad_set_typed_form_variable_filter /gc/admin/domain-top.tcl {user_id fail}
    ad_set_typed_form_variable_filter /gc/admin/edit-ad-2.tcl {user_id fail}
    ad_set_typed_form_variable_filter /gc/admin/edit-ad.tcl {user_id fail}
    ad_set_typed_form_variable_filter /gc/domain-top.tcl {user_id fail}
    ad_set_typed_form_variable_filter /glossary/one.tcl {user_id fail}
    ad_set_typed_form_variable_filter /glossary/term-edit-2.tcl {user_id fail}
    ad_set_typed_form_variable_filter /glossary/term-edit.tcl {user_id fail}
    ad_set_typed_form_variable_filter /glossary/term-new-2.tcl {user_id fail}
    ad_set_typed_form_variable_filter /glossary/term-new-3.tcl {user_id fail}
    ad_set_typed_form_variable_filter /groups/admin/group/spam-item.tcl {user_id fail}
    ad_set_typed_form_variable_filter /groups/group-new-3.tcl {user_id fail}
    ad_set_typed_form_variable_filter /homepage/index.tcl {user_id fail}
    ad_set_typed_form_variable_filter /intranet/customers/ae-2.tcl {user_id fail}
    ad_set_typed_form_variable_filter /intranet/customers/ae.tcl {user_id fail}
    ad_set_typed_form_variable_filter /intranet/customers/index.tcl {user_id fail}
    ad_set_typed_form_variable_filter /intranet/customers/primary-contact-2.tcl {user_id fail}
    ad_set_typed_form_variable_filter /intranet/customers/primary-contact-delete.tcl {user_id fail}
    ad_set_typed_form_variable_filter /intranet/customers/primary-contact-users-2.tcl {user_id fail}
    ad_set_typed_form_variable_filter /intranet/customers/primary-contact-users.tcl {user_id fail}
    ad_set_typed_form_variable_filter /intranet/customers/primary-contact.tcl {user_id fail}
    ad_set_typed_form_variable_filter /intranet/customers/view.tcl {user_id fail}
    ad_set_typed_form_variable_filter /intranet/employees/admin/bulk-edit.tcl {user_id fail}
    ad_set_typed_form_variable_filter /intranet/employees/admin/update-supervisor-2.tcl {user_id fail}
    ad_set_typed_form_variable_filter /intranet/facilities/ae-2.tcl {user_id fail}
    ad_set_typed_form_variable_filter /intranet/facilities/ae.tcl {user_id fail}
    ad_set_typed_form_variable_filter /intranet/facilities/primary-contact-2.tcl {user_id fail}
    ad_set_typed_form_variable_filter /intranet/facilities/primary-contact-delete.tcl {user_id fail}
    ad_set_typed_form_variable_filter /intranet/facilities/primary-contact.tcl {user_id fail}
    ad_set_typed_form_variable_filter /intranet/hours/ae-2.tcl {user_id fail}
    ad_set_typed_form_variable_filter /intranet/offices/ae-2.tcl {user_id fail}
    ad_set_typed_form_variable_filter /intranet/offices/ae.tcl {user_id fail}
    ad_set_typed_form_variable_filter /intranet/offices/primary-contact-2.tcl {user_id fail}
    ad_set_typed_form_variable_filter /intranet/offices/primary-contact-delete.tcl {user_id fail}
    ad_set_typed_form_variable_filter /intranet/offices/primary-contact.tcl {user_id fail}
    ad_set_typed_form_variable_filter /intranet/partners/ae-2.tcl {user_id fail}
    ad_set_typed_form_variable_filter /intranet/partners/ae.tcl {user_id fail}
    ad_set_typed_form_variable_filter /intranet/partners/index.tcl {user_id fail}
    ad_set_typed_form_variable_filter /intranet/partners/primary-contact-2.tcl {user_id fail}
    ad_set_typed_form_variable_filter /intranet/partners/primary-contact-delete.tcl {user_id fail}
    ad_set_typed_form_variable_filter /intranet/partners/primary-contact.tcl {user_id fail}
    ad_set_typed_form_variable_filter /intranet/partners/view.tcl {user_id fail}
    ad_set_typed_form_variable_filter /intranet/projects/ae-2.tcl {user_id fail}
    ad_set_typed_form_variable_filter /intranet/projects/ae.tcl {user_id fail}
    ad_set_typed_form_variable_filter /intranet/reports/missing-group-2.tcl {user_id fail}
    ad_set_typed_form_variable_filter /intranet/user-search.tcl {user_id fail}
    ad_set_typed_form_variable_filter /intranet/users/info-update-2.tcl {user_id fail}
    ad_set_typed_form_variable_filter /neighbor/comment-add-2.tcl {user_id fail}
    ad_set_typed_form_variable_filter /neighbor/view-one.tcl {user_id fail}
    ad_set_typed_form_variable_filter /registry/add-entry.tcl {user_id fail}
    ad_set_typed_form_variable_filter /wp/invite-2.tcl {user_id fail}
    ad_set_typed_form_variable_filter /wp/presentation-edit-2.tcl {user_id fail}
    ad_set_typed_form_variable_filter /wp/style-edit-2.tcl {user_id fail}
    ad_set_typed_form_variable_filter /wp/style-image-delete.tcl {user_id fail}
    ad_set_typed_form_variable_filter /address-book/* address_book_id
    ad_set_typed_form_variable_filter /bannerideas/* idea_id
    # added topic, group_id, rowid,feature_msg_id,start_msg_id - ravi, neal
    ad_set_typed_form_variable_filter /bboard/* \
	    upload_id \
	    topic_id \
	    {msg_id word} \
	    {row_id word} \
	    {form_refers_to word} \
	    {refers_to word} \
	    bboard_upload_id \
	    group_id \
	    {start_msg_id word} \
	    {thread_id word} \
	    {html_p word} \
	    group_id \
	    {rowid word} \
	    {feature_msg_id word} \
	    {start_msg_id word} 
    # {topic noquote} \ commented out because topics CAN be quoted.
    ad_set_typed_form_variable_filter /bboard/admin-authorize* {* fail}
    #added msg_ids - ravi, neal
    ad_set_typed_form_variable_filter /bboard/admin-bulk-delete* deletion_ids \
	    {msg_ids noquote} 
    
    # ravi, neal
    ad_set_typed_form_variable_filter /bboard/admin* {one_line nocheck QQ}\
	    n_postings \
	    {start_date noquote} \
	    {end_date noquote} \
	    n_winners \
	    {from_address noquote} \
	    {subject noquote} 
    # added by ravi, neal    
    ad_set_typed_form_variable_filter /bboard/admin-bozo-pattern* \
	    {the_regexp noquote} \
	    {scope noquote} \
	    {message_to_user noquote} \
	    {creation_comment noquote} \
	    {the_regexp_old noquote}
    # added by ravi, neal
    ad_set_typed_form_variable_filter /bboard/admin-bulk* \
	    {deletion_ids noquote} \
	    {msg_ids noquote} 
    # added - ravi, neal
    ad_set_typed_form_variable_filter /bboard/add-new-alert* \
	    {presentation_type noquote} \
	    {moderation_policy noquote} \
	    {private_p  noquote} \
	    {notify_of_new_postings_p noquote}
    # added - ravi, neal
    ad_set_typed_form_variable_filter /bboard/admin-q-and-a* {category nocheck}
    # added - ravi, neal
    ad_set_typed_form_variable_filter /bboard/q-and-a* \
	    {category nocheck} \
	    {thread_id word} \
	    {new_category_p word}
    # added - ravi, neal
    ad_set_typed_form_variable_filter /bboard/admin-update* \
	    {expiration_days} \
	    {interest_level} \
	    {uploads_anticipated noquote}
    # added - ravi, neal
    ad_set_typed_form_variable_filter /bboard/cc.tcl {key nocheck QQ}
    # added - ravi, neal
    ad_set_typed_form_variable_filter /bboard/confirm.tcl \
	    {notify word} \
	    {q_and_a_p word}
    # added - ravi, neal
    ad_set_typed_form_variable_filter /bboard/custom-q-and-a* {key nocheck}
    ad_set_typed_form_variable_filter /bboard/do-delete.tcl \
	    {submit_button noquote} \
	    {explanation nocheck QQ} \
	    {explanation_from noquote} \
	    {explanation_to noquote} \
	    {deletion_list noquote} 
    ad_set_typed_form_variable_filter /bboard/statistics.tcl {show_total_bytes_p word}
    ad_set_typed_form_variable_filter /bboard/insert-msg.tcl \
	    {file_extension noquote} \
	    {local_filename noquote} \
	    {tri_id word} \
	    {upload_file safefilename}
    ad_set_typed_form_variable_filter /bboard/threads-one-day* {kickoff_date noquote} \
	    {all_p word} \
	    {julian_date noquote}
    ad_set_typed_form_variable_filter /bboard/update* \
	    {q_and_a_categorized_p word} \
	    {q_and_a_solicit_categorized_p word} \
	    {q_and_a_categorization_user_extensible_p word} \
	    {q_and_a_new_days word} \
	    {maintainer_name nocheck} \
	    {maintainer_email noquote} \
	    {admin_password nocheck} 
    ad_set_typed_form_variable_filter /bboard/urgent-requests {archived_p word}
    #  ad_set_typed_form_variable_filter /bboard/usgeospatial* \
	    epa_region \
	    {usps_abbrev noquote} \
	    {tri_id word} \
	    {fips_country_code word} \
	    {force_p word} \
	    {zip_code word} 
    
    ad_set_typed_form_variable_filter /bookmarks/* bookmark_id deleteable_link
    ad_set_typed_form_variable_filter /bookmarks/public-bookmarks-for-one-user.tcl viewed_user_id
    # changed this mispelled calender
    ad_set_typed_form_variable_filter /calendar/* comment_id calendar_id
    ad_set_typed_form_variable_filter /chat/* chat_room_id chat_msg_id
    ad_set_typed_form_variable_filter /chat/history-one-day.tcl {the_date noquote}
    ad_set_typed_form_variable_filter /comments/* page_id comment_id
    ad_set_typed_form_variable_filter /comments/attachment/* third_urlv_integer
    # found by jon,lin
    ad_set_typed_form_variable_filter /general-comments/* comment_id
    ad_set_typed_form_variable_filter /general-comments/attachment/* third_urlv_integer
    ad_set_typed_form_variable_filter /ecommerce/* {file_path safefilename} \
	    category_id \
	    subcategory_id \
	    subsubcategory_id \
	    gift_certificate_id \
	    shipment_id \
	    order_id \
	    product_id \
	    address_id\
	    comment_id
    ad_set_typed_form_variable_filter /homepage/* {scr_name noquote} \
	    {upload_file safefilename} \
	    filesystem_node \
	    new_node 
    ad_set_typed_form_variable_filter /links/* page_id
    ad_set_typed_form_variable_filter /poll/* pole_id choice_id
    ad_set_typed_form_variable_filter /wp/* attach_id \
	    presentation_id \
	    {attachment safefilename} \
	    slide_id \
	    {inline_image_p word} \
	    {display noquote} \
	    style_id \
	    {image safefilename}
    ad_set_typed_form_variable_filter /pvt/portrait/* {upload_file safefilename}
    ad_set_typed_form_variable_filter /custom-sections/* section_id
    ad_set_typed_form_variable_filter /custom-sections/file/* content_file_id
    ad_set_typed_form_variable_filter /download/admin/* version_id \
	    download_id \
	    {release_date noquote} \
	    {upload_file safefilename} \
	    {pseudo_filename safefilename} \
	    {status word}
    ad_set_typed_form_variable_filter /download/* version_id \
	    download_id
    ad_set_typed_form_variable_filter /dw/* query_id
    ad_set_typed_form_variable_filter /events/* file_id \
	    on_what_id \
	    {upload_file safefilename} \
	    {on_which_table word} \
	    event_id \
	    activity_id \
	    reg_id \
	    price_id \
	    order_id
    #  ad_set_typed_form_variable_filter /admin/contest/* domain_id
    ad_set_typed_form_variable_filter /admin/content-sections/* sort-key \
	    section_id
    ad_set_typed_form_variable_filter /admin/chat/* group_id \
	    ad_set_typed_form_variable_filter /admin/users/view-verbose* {order_by word}
    ad_set_typed_form_variable_filter /admin/users/view* {order_by word}
    ad_set_typed_form_variable_filter /admin/bannerideas/*    idea_id
    ad_set_typed_form_variable_filter /admin/ecommerce/* product_id
    ad_set_typed_form_variable_filter /admin/ecommerce/products/* {csv_file safefilename} \
	    template_id 
    ad_set_typed_form_variable_filter /admin/custom-sections/upload-image-1*  group_id \
	    on_what_id \
	    section_id \
	    content_file_id \
	    {upload_file nocheck} \
	    {file_name safefilename}
    
    ad_set_typed_form_variable_filter /admin/display/upload-logo-2* {upload_file safefilename} \
	    group_id
    ad_set_typed_form_variable_filter /admin/spam/upload-file-2* {path safefilename} \
	    {clientfile safefilename}
    ad_set_typed_form_variable_filter /admin/spam/upload-file-to-spam* spam_id \
	    {clientfile safefilename} \
	    {data_type word}
    ad_set_typed_form_variable_filter /admin/categories/* category_id \
	    parent_category_id \
	    profiling_weight
    ad_set_typed_form_variable_filter /admin/chat/create-room-2* group_id
    ad_set_typed_form_variable_filter /admin/content-sections/content-section-add-2* sort_key \
	    section_id
    # added all besides user_id
    ad_set_typed_form_variable_filter /* \
	    user_id \
	    user_id_from_search \
	    {first_names_from_search noquote} \
	    {last_name_from_search noquote} \
	    {email_from_search noquote} \
	    {email noquote} \
	    {return_url noquote}

}

set secret_tokens_exists [db_string secret_tokens_exists "select decode(count(*),0,0,1) from secret_tokens"]

if { $secret_tokens_exists == 0 } {
    populate_secret_tokens_db
}

ns_log Notice "Creating secret_tokens ns_cache..."
ns_cache create secret_tokens -size 32768
ns_log Notice "Populating secret_tokens ns_cache..."
populate_secret_tokens_cache
