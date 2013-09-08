# /admin/poll/choice-new.tcl

ad_page_contract { 
    Inserts a new choice, or re-orders existing choices
    @param poll_id the ID of the poll
    @param choice_id the ID of the choice
    @param order option list
    @choice_new place in list of choices for new choice
    @label name of new choice
    @action reorder or add new choice

    @cvs-id choice-new.tcl,v 3.4.2.8 2001/01/11 20:15:56 khy Exp
} {
    poll_id:notnull,naturalnum
    choice_id:notnull,naturalnum,verify
    action:notnull
    label:optional
    order:array,optional
    choice_new:notnull,naturalnum
}

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

foreach order_choice_id [array names order] {
    set order_number $order($order_choice_id)
    if [info exists seen_order_p($order_number)] {
	incr exception_count
	append exception_text "<li> You have a repeated number in your re-ordering of items."
	break
    } else {
	set seen_order_p($order_number) 1
    }

    set choice_order($order_choice_id) $order_number
}


if { !$just_reorder_p } {
    if [info exists seen_order_p($choice_new)] {
	incr exception_count
	append exception_text "<li> Your new choice has the same ordering number as an existing choice"
    }

    if { ![info exists label] || [empty_string_p $label] } {
	incr exception_count
	append exception_text "<li> Please name your new choice"
    }
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

# insert the value



if { !$just_reorder_p } {
set already_p [db_string get_already_has_choice "select count(*) as cnt from
poll_choices where poll_id=:poll_id and label=:label"]
if { $already_p > 0 } {
    ad_return_complaint 1 "A choice with that label already exists!"
    return
}

    set insert_sql "
insert into poll_choices
    (choice_id, poll_id, label, sort_order)
values
    (:choice_id, :poll_id, :label, :choice_new)
"

    if [catch { db_dml insert_poll_choice $insert_sql } errmsg ] {
	doc_return  200 text/html "
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
    
    db_transaction {
    
    foreach i [array names order] {
	set sort_order $order($i)
	db_dml reorder_choices "
update poll_choices
   set sort_order = :sort_order
 where choice_id = :i
"
    }
   
    }
}

db_release_unused_handles

# update memoized choices

util_memoize_flush "poll_labels_internal $poll_id"

# redirect back to where they came from

ad_returnredirect "one-poll?[export_url_vars poll_id]"













