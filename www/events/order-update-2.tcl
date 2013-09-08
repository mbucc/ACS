ad_page_contract {
    @param reg_id the ID for this even registration
    @param phone_number contact phone number for the attendee
    @param attending_reason
    @param org organization the attendee is with
    @param title_at_org position at that organization
    @param where_heard where they heard about us
    @param need_hotel_p do they need a hotel room
    @param need_car_p do they need a rental car
    @param need_plane_p do they need a flight reservation
    @param line1 address, line 1
    @param line2 address, line 2
    @param city
    @param state
    @param postal_code
    @param country_code
    @param customfield

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id order-update-2.tcl,v 3.5.2.7 2000/08/11 17:44:33 kevin Exp
} {
    {reg_id:integer,notnull}
    {phone_number:notnull}
    {attending_reason:trim [db_null]}
    {org:trim [db_null]}
    {title_at_org:trim [db_null]}
    {where_heard:trim [db_null]}
    {need_hotel_p "f"}
    {need_car_p "f"}
    {need_plane_p "f"}
    {line1:trim,notnull}
    {line2:trim,optional [db_null]}
    {city:trim,notnull}
    {state:optional [db_null]}
    {postal_code:trim,notnull}
    {country_code:notnull}    
    {customfield:array,optional}
} -validate {
    long_reason -requires {attending_reason} {
	if { [string length $attending_reason] > 4000 } {
	    ad_complain "Please limit your reason for 
	    attending to 4000 characters."
	}
    }

    long_where_heard -requires {where_heard} {
	if { [string length $where_heard] > 4000 } {
	    ad_complain "Please keep where you heard 
	    about this activity to less than 4000 characters."
	}
    }

    state_if_us -requires {country_code} {
	if {$country_code == "us" && ![exists_and_not_null state]} {
	    ad_complain "You forgot to enter your state"
	}
    }

} -errors {
    reg_id "This page came in without a registration id"
    phone_number  "You forgot to enter your telephone number"
    line1 "You forgot to enter your address"
    city "You forgot to enter your city"
}

set user_id [ad_maybe_redirect_for_registration]



#make sure this reg_id belongs to this user
set reg_check [db_string evnt_check_reg "select
count(*) from events_reg_not_canceled 
where reg_id = :reg_id
and user_id = :user_id"]

if {!$reg_check} {
    ad_return_warning "Registration Not Found" "Registration $reg_id
    was not found or does not belong to you."
    return
}

set event_id [db_string evnt_sel_evnt_info "select
p.event_id from events_prices p, events_registrations r
where r.reg_id = :reg_id
and p.price_id = r.price_id"]

#all set so do the update

db_transaction {

#try to store the user's contact info
db_dml unused "update users_contact
set home_phone = :phone_number,
ha_line1 = :line1,
ha_line2 = :line2, 
ha_city = :city, 
ha_state = :state, 
ha_postal_code = :postal_code, 
ha_country_code = :country_code
where user_id = :user_id
" 

if {[db_resultrows] == 0} {
    db_dml insert_contact "insert into users_contact
    (user_id, home_phone, ha_line1, ha_line2, ha_city, ha_state, 
    ha_postal_code, ha_country_code)
    values
    (:user_id, :phone_number, :line1, :line2,
    :city, :state,:postal_code, 
    :country_code)"
}

#update the registration info
db_dml unused "update events_registrations
set org = :org, 
title_at_org = :title_at_org, 
attending_reason = :attending_reason, 
where_heard = :where_heard
where reg_id = :reg_id
" 

#update the custom fields
set table_name [events_helper_table_name $event_id]

# store the custom fields.
# here c_n_l_l is a list of (c_n, p_n, c_a_t) triples.
set column_name_list_list [db_list_of_lists evnt_get_custom_fields "
select column_name,
pretty_name, column_actual_type,
'customfield(' || column_name || ')' as array_column_name
from events_event_fields
where event_id = :event_id
order by sort_key"]


# prepare for the coming foreach { append ... } loop
set columns_for_insert ""
set values_for_insert  ""

   
set clob_count 0 
set clob_names ""; set clob_vars ""; set clob_values "";

foreach column_name_list $column_name_list_list {
    set column_name [lindex $column_name_list 0] 
    set pretty_name [lindex $column_name_list 1] 
    set column_type [lindex $column_name_list 2]
    set array_column_name [lindex $column_name_list 3]
    set column_value [set $array_column_name]
    if { ![exists_and_not_null column_value] } {
	set column_value "NULL"
    }
    
    #see if the column is a varchar and thus has a size limit
    if {[regexp {varchar([0-9]*)\((.*)\)} $column_type match type size]} {
	if {[string length $column_value] > $size} {
	    db_abort_transaction
	    db_release_unused_handles
	    ad_return_complaint 1 "
	    <li>Please limit your $pretty_name to $size characters.\n"
	    return
	}
    }	

    #check for naughty html
    if { ![empty_string_p [ad_check_for_naughty_html $column_value]] } {
	db_abort_transaction
	db_release_unused_handles
	ad_return_complaint 1 "[ad_check_for_naughty_html $column_value]\n"
	return
    }    
    
    #a hack to let the eval statement handle quotes better
    regsub -all {\"} $column_value { \&quot } column_value
    
    if { [string compare $column_type "clob"] == 0 } { 
	incr clob_count	   
	lappend clob_names  $column_name
	lappend clob_values $column_value
	lappend clob_vars   ":$clob_count" 
	# empty clob is filled by the 'returning...' clause
	lappend columns_for_insert $column_name
	lappend values_for_insert "empty_clob()"
    } else {
	lappend columns_for_insert $column_name
	lappend values_for_insert "'[DoubleApos $column_value]'"
    }
}
lappend columns_for_insert "user_id"
lappend values_for_insert $user_id

set clob_update_cmd " db_dml update_info_table \"update $table_name
set "

#don't set this to the length plus 1 (accounting for user_id) because
#we don't want to update the user_id
set count [llength $column_name_list_list]
set i 0
while {$i < $count} {
    if {$i == [expr $count - 1]} {
	#don't need a comma on the last one
	append clob_update_cmd "\[lindex \$columns_for_insert $i\] = 
	\[lindex \$values_for_insert $i\] "
    } else {
	append clob_update_cmd "\[lindex \$columns_for_insert $i\] = 
	\[lindex \$values_for_insert $i\], "
    }
    
    incr i
}
append clob_update_cmd "where user_id = $user_id
returning  [join $clob_names ", "] 
into  [join $clob_vars  ", "]
\" -clobs [list \$clob_values]"

set columns_sql [join $columns_for_insert ", "]
set values_sql  [join $values_for_insert  ", "]

#delay evaluation of the variables until the eval statement
set clob_insert_cmd "db_dml insert_custom_fields \"insert into $table_name
(\$columns_sql)
values
(\$values_sql)
returning  [join $clob_names ", "] 
into  [join $clob_vars  ", "]
\" -clobs [list \$clob_values]"

if { $clob_count > 0 } {   
    #DEBUG STUFF
    #ReturnHeaders 
    #regsub -all {\\} $clob_insert_cmd "" clob_insert_check
    #ns_write "<pre>{[subst $clob_insert_check]}</pre><p>"
    #regsub -all {\\} $clob_update_cmd "" clob_update_check
    #ns_write "<pre>{[subst $clob_update_check]}</pre><p>"

    set update_check [db_string sel_update_check "select
    count(*) from $table_name
    where user_id = :user_id"]

    if {$update_check > 0} {
	regsub -all {\\} $clob_update_cmd "" clob_update_cmd
	set clob_update_cmd [subst $clob_update_cmd]
	eval $clob_update_cmd
    } else {
	regsub -all {\\} $clob_insert_cmd "" clob_insert_cmd
	set clob_insert_cmd [subst $clob_insert_cmd]
	eval $clob_insert_cmd
    }
} else {
    set update_cmd "update $table_name set "
    set i 0
    while {$i < [expr $count + 1]} {
	if {$i == $count} {
	    #don't need a comma on the last one
	    append update_cmd "[lindex $columns_for_insert $i] = 
	    [lindex $values_for_insert $i] "
	} else {
	    append update_cmd "[lindex $columns_for_insert $i] = 
	    [lindex $values_for_insert $i], "
	}
	
	incr i
    }
    append update_cmd " where user_id = $user_id"

    #try to update first--then try to insert	
    if {$i > 0} {
	db_dml evnt_update_cmd $update_cmd
	set resultrows_count [db_resultrows]
    } else {
	set resultrows_count 0
    }
    
    if {$resultrows_count == 0} {
	db_dml evnt_insert_cmd "insert into $table_name
	($columns_sql)  
	values
	($values_sql)"
    }
}

}

set whole_page "
[ad_header "Registration Updated"]
<h2>Registration Updated</h2>
[ad_context_bar_ws [list "index.tcl" "Events"] "Update Registration"]
<hr>
You registration information has been updated.  You will be notified
shortly of any changes in your registration status.  Thanks
for your time.
[ad_footer]
"

#get the proper info for e-mailing
set contact_email [db_string sel_contact_email "select u.email
from users u, event_info ei, events_events e
where e.event_id = :event_id
and ei.group_id = e.group_id
and u.user_id = ei.contact_user_id"]

set user_email [db_string sel_user_email "select
	email from users
  where  user_id=:user_id"]

set email_subject "Updated Registration Info"

set email_body "$user_email has updated his registration information
for
[events_pretty_event $event_id]

Please come to review his registration:

[ad_parameter SystemURL]/events/admin/reg-view.tcl?reg_id=$reg_id
"

#release the db handle


doc_return  200 text/html $whole_page

#send the email
if [catch { ns_sendmail $contact_email $contact_email $email_subject $email_body } errmsg] {
    ns_log Notice "failed sending email to $contact_email about
    updated registration info: $errmsg"
} 
