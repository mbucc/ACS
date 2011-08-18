# $Id: review-add.tcl,v 3.0 2000/02/06 03:20:49 ron Exp $
set_the_usual_form_variables
# product_id, publication, display_p, review
# author_name, review_date

set product_name [ec_product_name $product_id]

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

ReturnHeaders
ns_write "[ad_admin_header "Confirm Review of $product_name"]

<h2>Confirm Review of $product_name</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Products"] [list "one.tcl?[export_url_vars product_id]" $product_name] [list "reviews.tcl?[export_url_vars product_id product_name]" "Professional Reviews"] "Confirm Review"]

<hr>

<table>
<tr>
<td>Summary</td>
<td>[ec_product_review_summary $author_name $publication $review_date]</td>
</tr>
<tr>
<td>Display on web site?</td>
<td>[util_PrettyBoolean $display_p]</td>
</tr>
<tr>
<td>Review</td>
<td>$review</td>
</tr>
</table>
"

set db [ns_db gethandle]
set review_id [database_to_tcl_string $db "select ec_product_review_id_sequence.nextval from dual"]

ns_write "<form method=post action=review-add-2.tcl>
[export_form_vars product_id publication display_p review review_id author_name review_date]

<center>
<input type=submit value=\"Confirm\">
</center>
</form>

[ad_admin_footer]
"
