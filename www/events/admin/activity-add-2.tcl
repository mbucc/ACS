# File: events/admin/activity-add-2.tcl
# Purpose:  Adds an event with the input from activity-add.tcl.   
#     Checks admin's inputs, catches errors or redirects to activities.tcl.
#   Note:  default_price should be defined at the start; it's set here to 
#     the magic number 0. 
#####
ad_page_contract {

    Adds an event with the input from activity-add.tcl.   
    Checks admin's inputs, catches errors or redirects to activities.tcl.

    @param activity_id the new activity_id
    @param group_id the activity's owning group
    @param creator_id the activity's creator
    @param short_name the activity's name
    @param description the activity's description
    @param available_p is the activity available
    @param detail_url a url for the activity
    @param default_contact_user_id the activity's default contact

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id activity-add-2.tcl,v 3.6.2.7 2001/01/10 18:11:12 khy Exp
} {
    {activity_id:integer,verify}
    {group_id:integer,optional}
    {creator_id:integer}
    {short_name:trim,notnull}
    {description:html,trim,notnull}
    {available_p}
    {detail_url [db_null]}
    {default_contact_user_id:integer,optional}
}


#error check
#set exception_count 0
#set exception_text ""

#if {![valid_number_p $default_price]} {
#    append exception_text  "<li>You did not enter a valid number for the price"
#    incr exception_count
#}

#if {[empty_string_p ${short_name}]} {
#    append exception_text "<li>Please enter an activity name.\n"
#    incr exception_count
#}

#if {$exception_count > 0} {
#    ad_return_complaint exception_count $exception_text
#    return 0
#}

if {![exists_and_not_null default_contact_user_id]} {
    set default_contact_user_id "[db_null]"
}

if {[exists_and_not_null group_id]} {
    db_dml new_activity "insert into events_activities
     (activity_id, group_id, creator_id, short_name, description, 
      available_p, detail_url, default_price, default_contact_user_id)
    values
     (:activity_id, :group_id, :creator_id, :short_name, :description, 
      :available_p, :detail_url, 0, :default_contact_user_id)"
} else {
    db_dml new_activity "insert into events_activities
     (activity_id, creator_id, short_name, description, 
      available_p, detail_url, default_price, default_contact_user_id)
    values
     (:activity_id, :creator_id, :short_name, :description, 
      :available_p, :detail_url, 0, :default_contact_user_id)"
}

# If we've gotten this far without trouble, return to the activities list
# to verify this new one has been added there.
db_release_unused_handles
ad_returnredirect "activities.tcl"

##### EOF
