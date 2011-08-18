set_the_usual_form_variables

#activity_id, short_name, description, available_p, group_id, default_price

#if {![valid_number_p $default_price]} {
#    ad_return_complaint 1 "<li>You did not enter a valid number for the price"
#    return
#}

set db [ns_db gethandle]

if {[exists_and_not_null group_id]} {
    ns_db dml $db "update events_activities set
    group_id = $group_id,
    short_name='$QQshort_name', 
    description='$QQdescription', 
    available_p='$QQavailable_p',
    detail_url='$QQdetail_url'
    where activity_id = $activity_id"
} else {
    ns_db dml $db "update events_activities set
    group_id=null,
    short_name='$QQshort_name', 
    description='$QQdescription', 
    available_p='$QQavailable_p',
    detail_url='$QQdetail_url'
    where activity_id = $activity_id"
}
#    default_price=$default_price

# if no errors cropped up, we redirect to this activity's display page.
ad_returnredirect "activity.tcl?activity_id=$activity_id"

