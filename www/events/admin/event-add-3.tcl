# File:  events/admin/event-add-3.tcl
# Owner: bryanche@arsdigita.com
# Purpose: Verify event-add input, return error mesg or add event
#     info to database. 
#####

ad_page_contract {
    Purpose: Verify event-add input, return error mesg or add event
    info to database. 

    @param event_id the event_id to create
    @param activity_id activity type of the event
    @param display_after a registration confirmation message
    @param reg_cancellable_p can this event be canceled
    @param price_id the event's default price
    @param product_id optional product_id for hooking into ecommerce
    @param contact_user_id the event's contact person
    @param max_people the max number of people that can register for this event
    @param reg_needs_approval_p does a registration need to be approved?
    @param reg_cancellable_p can a registration be canceled
    @param venue_id the event's venue
    @param refreshments_note refreshment note for this event
    @param av_note a/v note for this event
    @param additional_note additional note for this event

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id event-add-3.tcl,v 3.15.2.9 2001/01/10 18:19:34 khy Exp
} {
    {event_id:naturalnum,notnull,verify}
    {activity_id:naturalnum,notnull}
    {display_after:html,trim,notnull}
    {reg_cancellable_p}
    {price_id:integer,notnull,verify}
    {product_id:integer,optional}
    {contact_user_id:integer,notnull}
    {max_people:naturalnum,optional}
    {reg_needs_approval_p}
    {reg_cancellable_p}
    {venue_id:naturalnum,notnull}
    {refreshments_note:html,trim [db_null]}
    {av_note:html,trim [db_null]}
    {additional_note:html,trim [db_null]}
}

set user_id [ad_maybe_redirect_for_registration]

#check for double_click
set db_click_check [db_string evnt_add_dbl_clk "select
count(*) from events_events
where event_id = :event_id"]
if {$db_click_check > 0} {
    db_release_unused_handles
    ad_return_warning "Event Already Exists" "
    An event with this ID has already been created.  Perhaps
    you double-clicked?"
    return
}

set exception_text ""
set exception_count 0

#if {![valid_number_p $price]} {
#    append exception_text  "<li>You did not enter a valid number for the price"
#    incr exception_count
#}

### Error checking
## simple input checks
if { [catch {ns_dbformvalue [ns_conn form] reg_deadline datetime reg_deadline_value} err_msg]} {
    incr exception_count
    append exception_text "<li>Please enter a valid registration deadline.\n"
}
if { [catch {ns_dbformvalue [ns_conn form] start_time datetime start_time_value} err_msg]} {
    incr exception_count
    append exception_text "<li>Please enter a valid start time.\n"
}
if { [catch {ns_dbformvalue [ns_conn form] end_time datetime end_time_value} err_msg]} {
    incr exception_count
    append exception_text "<li>Please enter a valid end time.\n"
}

## Return with errors if any
if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

set ip_address [ns_conn peeraddr]

## Date checking 
set time_check [db_0or1row check_time "select '1_time_check' from dual 
   where to_date(:start_time_value, 'YYYY-MM-DD HH24:MI:SS')  
           < to_date(:end_time_value, 'YYYY-MM-DD HH24:MI:SS')
     and to_date(:reg_deadline_value, 'YYYY-MM-DD HH24:MI:SS') 
           <= to_date(:start_time_value, 'YYYY-MM-DD HH24:MI:SS')
     and to_date(:reg_deadline_value, 'YYYY-MM-DD HH24:MI:SS') 
           > sysdate
"]
if {!$time_check} {
    ad_return_complaint 1 "<li>Please make sure your start time is
    before your end time, your registration deadline 
    is no later than your start time, and your registration deadline
    is not in the past.\n"
    return
}

db_transaction {

    #create the user group for this event
    set name [db_string activity_name "select short_name
    from events_activities where activity_id = :activity_id"]
    set location [events_pretty_venue $venue_id]
    set group_id [events_group_create $name $start_time_value $location]

    if {$group_id == 0} {
	db_abort_transaction
	ad_return_error "Couldn't create group" "We were unable to create a user group for your new event."
	return
    }

    #make this user an administrator of the user group
    db_dml insert_group_admin "insert into user_group_map 
    (group_id, user_id, role, mapping_user, mapping_ip_address) 
    select :group_id, :user_id, 'administrator', :user_id, :ip_address
    from dual 
    where not exists (select user_id from user_group_map 
                      where group_id = :group_id 
                      and user_id = :user_id)"

    #store the relevant info for this event into the event's user group
    db_dml evnt_info_insert "insert into event_info 
    (group_id, contact_user_id)
    values
    (:group_id, :contact_user_id)"

    #TODO: UPDATE THE ABOVE INSERT TO HANDLE AV_NOTE, REFRESHMENTS_NOTE, ETC.

    if {![exists_and_not_null max_people]} {
	set max_people "null"
    }

    #create the event
    db_dml insert_event "insert into events_events
    (event_id, activity_id, venue_id, display_after,
    max_people, av_note, refreshments_note, additional_note,
    start_time, end_time, reg_deadline, reg_cancellable_p, group_id,
    reg_needs_approval_p, creator_id
    )
    values
    ($event_id, $activity_id, $venue_id,  '[DoubleApos $display_after]', 
    $max_people, empty_clob(), empty_clob(), empty_clob(),
    to_date('$start_time_value', 'YYYY-MM-DD HH24:MI:SS'), 
    to_date('$end_time_value', 'YYYY-MM-DD HH24:MI:SS'),
    to_date('$reg_deadline_value', 'YYYY-MM-DD HH24:MI:SS'),
    '$reg_cancellable_p', $group_id, '$reg_needs_approval_p',
    $user_id)
    returning av_note, refreshments_note, additional_note
    into :1, :2, :3" -clobs [list $av_note $refreshments_note $additional_note]

    ## no ecommerce yet
    #create the ec product
    #db_dml unused "insert into ec_products
    #(product_id, product_name, creation_date, price, available_date,
    #last_modified, last_modifying_user, modified_ip_address)
    #values
    #($product_id, 'Normal Price', sysdate, $price, sysdate,
    #sysdate, $user_id, '[DoubleApos [ns_conn peeraddr]]')"

    ## create the event price
    db_dml insert_price "insert into events_prices
    (price_id, event_id, description, price, expire_date, available_date)
    values
    (:price_id, :event_id, 'Normal Price', 0, 
    to_date(:reg_deadline_value, 'YYYY-MM-DD HH24:MI:SS'),
    sysdate)"

    #create the event's fields table and add the default fields
    #from the activity
    set table_name [events_helper_table_name $event_id]
    db_dml create_info_table "create table $table_name (
    user_id integer primary key references users)"

    db_foreach default_field_sel "select
    column_name, pretty_name, column_type, column_actual_type,
    column_extra, sort_key
    from events_activity_fields
    where activity_id = :activity_id" {
	if {![catch {db_dml event_info_add_col "alter table $table_name
	add ($column_name $column_actual_type $column_extra)"} errmsg]} {
	    db_dml event_field_inesrt "insert into events_event_fields
	    (event_id, column_name, pretty_name, column_type, 
	    column_actual_type,
	    column_extra, sort_key)
	    values
	    (:event_id, :column_name, :pretty_name, 
	    :column_type, 
	    :column_actual_type,
	    :column_extra, :sort_key)"
	}
    }

    #create default organizer roles from the activity
    db_foreach org_roles_sel "select
    role, responsibilities, public_role_p
    from events_activity_org_roles
    where activity_id = :activity_id" {
	db_dml org_role_insert "insert into events_event_organizer_roles
	(role_id, event_id, role, responsibilities, public_role_p)
	values
	(events_event_org_roles_seq.nextval, :event_id, :role,
	:responsibilities, :public_role_p)"
    }
    
    ## Clean up, return to event.tcl page.

}

db_release_unused_handles

ad_returnredirect "event.tcl?event_id=$event_id"

##### EOF
