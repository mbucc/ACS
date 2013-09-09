# /admin/conversion/sequence-update.tcl


ad_page_contract {
    for the HP MiniPress project
    documented and "improved" by philg@mit.edu on October 30, 1999

    for each sequence in the Oracle database, we query to figure out the maximum 
    key that is being used.  We then drop and recreate the sequence starting at 
    this max value + 1 (or 1 if there aren't any rows yet in the table).

    Note that this rude behavior is required by Oracle; you can't ALTER SEQUENCE
    to move to a new next value (at least not in Oracle 8.1.5).

    @author  randyg@arsdigita.com
    @creation-date July 1999 
    @cvs-id # sequence-update.tcl,v 3.2.2.5 2000/09/22 01:34:37 kevin Exp
} {

}

# each sublists has sequence name, key name that uses the sequence, table name 

set html_string ""

# there must be a better way

set sequences [list]
lappend sequences [list idea_id_sequence idea_id bannerideas] 
lappend sequences [list bboard_upload_id_sequence bboard_upload_id bboard_uploaded_files] 
lappend sequences [list calendar_id_sequence calendar_id calendar]
lappend sequences [list chat_room_id_sequence chat_room_id chat_rooms] 
lappend sequences [list chat_msg_id_sequence chat_msg_id chat_msgs] 
lappend sequences [list classified_ad_id_sequence classified_ad_id classified_ads] 
lappend sequences [list user_id_sequence user_id users] 
lappend sequences [list category_id_sequence category_id categories] 
lappend sequences [list page_id_sequence page_id static_pages] 
lappend sequences [list comment_id_sequence comment_id comments] 
lappend sequences [list query_sequence query_id queries] 
lappend sequences [list incoming_email_queue_sequence id incoming_email_queue] 
lappend sequences [list general_comment_id_sequence comment_id general_comments] 
lappend sequences [list glassroom_host_id_sequence host_id glassroom_hosts] 
lappend sequences [list glassroom_cert_id_sequence cert_id glassroom_certificates] 
lappend sequences [list glassroom_module_id_sequence module_id glassroom_modules] 
lappend sequences [list glassroom_release_id_sequence release_id glassroom_releases]lappend sequences [list glassroom_logbook_entry_id_seq entry_id glassroom_logbook] 
lappend sequences [list intranet_offices_id_seq office_id intranet_offices] 
lappend sequences [list intranet_users_id_seq user_id intranet_users] 
lappend sequences [list proj_customer_id_seq customer_id proj_customers] 
lappend sequences [list proj_projects_id_seq project_id proj_projects] 
lappend sequences [list proj_deadline_id_seq deadline_id proj_deadlines] 
lappend sequences [list proj_hours_id_seq hours_id proj_hours] 
lappend sequences [list intranet_goals_id_seq goal_id intranet_goals] 
lappend sequences [list intranet_reviews_id_seq user_id intranet_reviews] 
lappend sequences [list users_order_id_sequence order_id users_orders] 
lappend sequences [list n_to_n_primary_category_id_seq category_id n_to_n_primary_categories] 
lappend sequences [list n_to_n_subcategory_id_seq subcategory_id n_to_n_subcategories] 
lappend sequences [list newsgroup_id_sequence newsgroup_id newsgroups] 
lappend sequences [list news_item_id_sequence news_item_id news_items]
lappend sequences [list stolen_registry_sequence stolen_id stolen_registry] 
lappend sequences [list spam_id_sequence spam_id spam_history] 
lappend sequences [list ticket_project_id_sequence project_id ticket_projects] 
lappend sequences [list ticket_assignment_id_sequence assignment_id ticket_assignments] 
lappend sequences [list ticket_issue_id_sequence msg_id ticket_issues] 
lappend sequences [list ticket_response_id_sequence response_id ticket_issue_responses] 
lappend sequences [list user_group_sequence group_id user_groups]

append html_string "<ul>"



# KS - there used to be a transaction here.  I removed it, because DDL 
# statement don't operate transactionally, they are instantaneous and 
# irrevokable. Danger, Will Robinson! Danger!


foreach sequence_set $sequences {
    set sequence_name [lindex $sequence_set 0]
    if {[catch {db_dml admin_sequence_update_drop_sequence "drop sequence $sequence_name"} errmsg]} {
	append html_string "<li><font color=red>error</font> in updating $sequence_name: $errmsg"
    } else {
	set column_name [lindex $sequence_set 1]
	set table_name [lindex $sequence_set 2]
	set maxvalue [db_string admin_sequence_update_get_max_sequence_value "select nvl(max($column_name)+1,1) from $table_name" -default ""] 
	db_dml admin_sequence_update_create_sequence "create sequence $sequence_name start with $maxvalue"
	append html_string  "<li>updated $sequence_name  new value = $maxvalue<br>"
    }

}

append html_string "</ul>"

db_release_unused_handles

doc_return 200 text/html $html_string



