# $Id: spam-log.tcl,v 3.0 2000/02/06 03:18:23 ron Exp $
set_form_variables 0
# maybe the pieces of start_date and end_date

proc spam_to_summary { db mailing_list_category_id mailing_list_subcategory_id mailing_list_subsubcategory_id user_class_id product_id full_last_visit_start_date full_last_visit_end_date } {
    if { ![empty_string_p $mailing_list_category_id] } {
	return "Members of the [ec_full_categorization_display $db $mailing_list_category_id $mailing_list_subcategory_id $mailing_list_subsubcategory_id] mailing list."
    }
    if { ![empty_string_p $user_class_id] } {
	return "Members of the [database_to_tcl_string $db "select user_class_name from ec_user_classes where user_class_id=$user_class_id"] user class."
    }
    if { ![empty_string_p $product_id] } {
	return "Customers who purchased [database_to_tcl_string $db "select product_name from ec_products where product_id=$product_id"] (product ID $product_id)."
    }
    if { ![empty_string_p $full_last_visit_start_date] } {
	return "Users whose last visit to the site was between [ec_formatted_full_date $full_last_visit_start_date] and [ec_formatted_full_date $full_last_visit_end_date]."
    }
}

ReturnHeaders

ns_write "[ad_admin_header "Spam Log"]
<h2>Spam Log</h2>
[ad_admin_context_bar [list "../index.tcl" "Ecommerce"] [list "index.tcl" "Customer Service Administration"] [list "spam.tcl" "Spam Users"] "Spam Log"]

<hr>
"

set db_pools [ns_db gethandle [philg_server_default_pool] 2]
set db [lindex $db_pools 0]
set db_sub [lindex $db_pools 1]

ec_report_get_start_date_and_end_date

set date_part_of_query "(spam_date >= to_date('$start_date 00:00:00','YYYY-MM-DD HH24:MI:SS') and spam_date <= to_date('$end_date 23:59:59','YYYY-MM-DD HH24:MI:SS'))"

ns_write "<form method=post action=\"[ns_conn url]\">
[ec_report_date_range_widget $start_date $end_date]
<input type=submit value=\"Alter date range\">
</form>

<table border>
<tr><th>Date</th><th>To</th><th>Text</th></tr>
"

set selection [ns_db select $db "select spam_text, mailing_list_category_id, mailing_list_subcategory_id, mailing_list_subsubcategory_id, user_class_id, product_id, to_char(last_visit_start_date,'YYYY-MM-DD HH24:MI:SS') as full_last_visit_start_date, to_char(last_visit_end_date,'YYYY-MM-DD HH24:MI:SS') as full_last_visit_end_date, to_char(spam_date,'YYYY-MM-DD HH24:MI:SS') as full_spam_date from ec_spam_log where $date_part_of_query order by spam_date desc"]

set rows_to_return ""
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append rows_to_return "<tr><td>[ec_formatted_full_date $full_spam_date]</td><td>[spam_to_summary $db_sub $mailing_list_category_id $mailing_list_subcategory_id $mailing_list_subsubcategory_id $user_class_id $product_id $full_last_visit_start_date $full_last_visit_end_date]</td><td>[ec_display_as_html $spam_text]</td>"
}

ns_write "$rows_to_return
</table>

[ad_admin_footer]
"