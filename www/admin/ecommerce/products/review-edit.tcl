# $Id: review-edit.tcl,v 3.0.4.1 2000/04/28 15:08:53 carsten Exp $
set_the_usual_form_variables
# product_id, publication, author_name, review_date, display_p, review, review_id

# Check review_date is correct format
set form [ns_getform]

set exception_count 0
set exception_text ""

# ns_dbformvalue $form review_date date review_date will give an error
# message if the day of the month is 08 or 09 (this octal number problem
# we've had in other places).  So I'll have to trim the leading zeros
# from ColValue.review%5fdate.day and stick the new value into the $form
# ns_set.

set "ColValue.review%5fdate.day" [string trimleft [set ColValue.review%5fdate.day] "0"]
ns_set update $form "ColValue.review%5fdate.day" [set ColValue.review%5fdate.day]

# check that either all elements are blank or date is formated 
# correctly for ns_dbformvalue
if { [empty_string_p [set ColValue.review%5fdate.day]] && 
     [empty_string_p [set ColValue.review%5fdate.year]] && 
     [empty_string_p [set ColValue.review%5fdate.month]] } {
	 set review_date ""
     } elseif { [catch  { ns_dbformvalue $form review_date date review_date} errmsg ] } {
    incr exception_count
    append exception_text "<li>The date or time was specified in the wrong format.  The date should be in the format Month DD YYYY.\n"
} elseif { ![empty_string_p [set ColValue.review%5fdate.year]] && [string length [set ColValue.review%5fdate.year]] != 4 } {
    incr exception_count
    append exception_text "<li>The year needs to contain 4 digits.\n"
}

# If errors, return error page
if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ns_conn url]?[export_entire_form_as_url_vars]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

set db [ns_db gethandle]

ns_db dml $db "update ec_product_reviews
set product_id=$product_id, publication='$QQpublication', author_name='$QQauthor_name', review_date='$review_date', review='$QQreview', display_p='$QQdisplay_p', last_modified=sysdate, last_modifying_user='$user_id', modified_ip_address='[DoubleApos [ns_conn peeraddr]]'
where review_id=$review_id
"

ad_returnredirect "review.tcl?[export_url_vars review_id]"
