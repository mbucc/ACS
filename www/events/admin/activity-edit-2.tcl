# File:  events/admin/activity-edit-2.tcl
# Owner: bryanche@arsdigita.com
# Purpose: apply the changes specified in activity-edit.
#   Note:  should insert default price, instead of leaving that alone. 
#            any necessary changes to a-e.tcl
#          should check user input better. 
#####

ad_page_contract {
    Apply the changes specified in activity-edit.

    @param activity_id the activity to edit
    @param short_name the activity's name
    @description the activity's description
    @available_p is the activity current or discontinued
    @group_id the activity's owning group
    @default_price the activity's default price
    @detail_url url with more info about the activity
    @default_contact_user_id the activity's default contact

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id activity-edit-2.tcl,v 3.8.2.5 2000/07/21 03:59:34 ron Exp
} {
    {activity_id:integer}
    {short_name:trim,notnull}
    {description:html,trim,optional}
    {available_p}
    {group_id:integer,optional}
    {default_price:optional}
    {detail_url:trim [db_null]}
    {default_contact_user_id:integer [db_null]}
}

if {[exists_and_not_null group_id]} {
    db_dml update_activity "update events_activities set
      group_id = :group_id,
      short_name=:short_name, 
      description=:description, 
      available_p=:available_p,
      detail_url=:detail_url,
      default_contact_user_id = :default_contact_user_id
    where activity_id = :activity_id"
} else {
    db_dml update_activity "update events_activities set
      group_id=null,
      short_name=:short_name, 
      description=:description, 
      available_p=:available_p,
      detail_url=:detail_url,
      default_contact_user_id = :default_contact_user_id
    where activity_id = :activity_id"
}

# if no errors cropped up, we redirect to this activity's display page.
ad_returnredirect "activity.tcl?activity_id=$activity_id"

##### EOF
