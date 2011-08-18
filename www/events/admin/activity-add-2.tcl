set db [ns_db gethandle]

set_the_usual_form_variables

#activity_id, group_id, creator_id, short_name, description, available_p, details_url

#error check
set exception_count 0
set exception_text ""

#if {![valid_number_p $default_price]} {
#    append exception_text  "<li>You did not enter a valid number for the price"
#    incr exception_count
#}


if {[empty_string_p ${short_name}]} {
    append exception_text "<li>Please enter an activity name\n"
    incr exception_count
}

if {$exception_count > 0} {
    ad_return_complaint exception_count $exception_text
    return 0
}

if {[exists_and_not_null group_id]} {
    ns_db dml $db "insert into events_activities
    (activity_id, group_id, creator_id, short_name, description, 
    available_p, detail_url, default_price)
    values
    ($activity_id, $group_id, $creator_id, '$QQshort_name', '$QQdescription', 
    '$QQavailable_p', '$QQdetail_url', 0)"
} else {
    ns_db dml $db "insert into events_activities
    (activity_id, creator_id, short_name, description, 
    available_p, detail_url, default_price)
    values
    ($activity_id, $creator_id, '$QQshort_name', '$QQdescription', 
    '$QQavailable_p', '$QQdetail_url', 0)"
}
#default_price

ad_returnredirect "activities.tcl"

