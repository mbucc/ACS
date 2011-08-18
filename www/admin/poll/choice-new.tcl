# $Id: choice-new.tcl,v 3.1.4.1 2000/04/28 15:09:14 carsten Exp $
# choice-new.tcl -- insert a new choice, or re-order existing choices

set_the_usual_form_variables
# expects poll_id, choice_id, count, action, label, option lists of the form
# 'order_$choice_id', 


# random preliminaries

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration


if { $action == "Change Ordering" } {
    set just_reorder_p 1
} else {
    set just_reorder_p 0
}


# collect the ordering options, then sanity check in the input


set exception_count 0
set exception_text ""

set form [ns_getform]
set form_size [ns_set size $form]

for { set i 0 } { $i < $form_size } { incr i } {
    set key [ns_set key $form $i]
    set value [ns_set value $form $i]

    if [regexp {order_([0-9]*)} $key match a_choice_id] {

	if [info exists seen_order_p($value)] {
	    incr exception_count
	    append exception_text "<li> You have repeated a number in your re-ordering of items."
	    break
	} else {
	    set seen_order_p($value) 1
	}

	set choice_order($a_choice_id) $value
    }
}

if { !$just_reorder_p } {
    if [info exists seen_order_p($choice_new)] {
	incr exception_count
	append exception_text "<li> Your new choice has the same ordering number as an existing choice"
    }
}



if { ![info exists poll_id] || [empty_string_p $poll_id] } {
    incr exception_count
    append exception_text "<li> poll_id is missing.  This could mean there's a problem in our software"
}

if { !$just_reorder_p } {

    if { ![info exists choice_id] || [empty_string_p $choice_id] } {
	incr exception_count
	append exception_text "<li> choice_id is missing.  This could mean there's a problem in our software"
    }

    if { ![info exists label] || [empty_string_p $label] } {
	incr exception_count
	append exception_text "<li> Please supply a label for the choice"
    }
}

    
if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}



# insert the value

set db [ns_db gethandle]

if { !$just_reorder_p } {

    set insert_sql "
insert into poll_choices
    (choice_id, poll_id, label, sort_order)
values
    ($choice_id, $poll_id, '$QQlabel', $choice_new)
"

    if [catch { ns_db dml $db $insert_sql } errmsg ] {
	ns_return 200 text/html "
[ad_admin_header "Error inserting poll"]
<h3>Error in inserting a poll</h3>
<hr>
There was an error in inserting the poll.  Here is
what the database returned:
<p>
<pre>
$errmsg
</pre>
[ad_admin_footer]
"
        return
    }
}


# update the sort orders of the existing choices

if [info exists choice_order] {
    
    ns_db dml $db "begin transaction"
    
    foreach i [array names choice_order] {
	ns_db dml $db "
update poll_choices
   set sort_order = $choice_order($i)
 where choice_id = $i
"
    }
   
    ns_db dml $db "end transaction"
}

ns_db releasehandle $db


# update memoized choices

validate_integer "poll_id" $poll_id
util_memoize_flush "poll_labels_internal $poll_id"

# redirect back to where they came from

ad_returnredirect "one-poll.tcl?[export_url_vars poll_id]"
