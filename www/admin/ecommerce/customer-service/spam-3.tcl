# $Id: spam-3.tcl,v 3.0.4.1 2000/04/28 15:08:41 carsten Exp $
set_the_usual_form_variables
# definitely: spam_id, subject, message, issue_type (select multiple), amount, expires
# possibly: mailing_list or user_class_id or product_id or (start_date & end_date) or user_id_list or viewed_product_id or category_id
# possibly: show_users_p

# no confirm page because they were just sent through the spell
# checker (that's enough submits to push)

set expires_to_insert [ec_decode $expires "" "null" $expires]

# get rid of stupid ^Ms
regsub -all "\r" $message "" message

set db_pools [ns_db gethandle [philg_server_default_pool] 2]
set db [lindex $db_pools 0]
set db_sub [lindex $db_pools 1]

# doubleclick protection
if { [database_to_tcl_string $db "select count(*) from ec_spam_log where spam_id=$spam_id"] > 0 } {
    ReturnHeaders
    ns_write "[ad_admin_header "Spam Sent"]
    <h2>Spam Sent</h2>
    [ad_admin_context_bar [list "../index.tcl" "Ecommerce"] [list "index.tcl" "Customer Service Administration"] "Spam Sent"]
    <hr>
    You are seeing this page because you probably either hit reload or pushed the Submit button twice.
    <p>
    If you wonder whether the users got the spam, just check the customer service issues for one of the users (all mail sent to a user is recorded as a customer service issue).
    [ad_admin_footer]
    "
    return
}

set return_url "[ns_conn url]?[export_entire_form_as_url_vars]"

set customer_service_rep [ad_get_user_id]

if {$customer_service_rep == 0} {
    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

# deal w/issue_type
set form [ns_getform]
set form_size [ns_set size $form]
set form_counter 0
set issue_type_list [list]
while { $form_counter < $form_size} {
    set form_key [ns_set key $form $form_counter]
    if { $form_key == "issue_type" } {
	set form_value [ns_set value $form $form_counter]
	if { ![empty_string_p $form_value] } {
	    lappend ${form_key}_list $form_value
	}
    }
    incr form_counter
}

# 1. Write row to spam log
# 2. Select the users to be spammed
# 3. For each user:
#    a. create interaction
#    b. create issue
#    c. create action
#    d. send email
#    e. perhaps issue gift_certificate

set mailing_list_category_id ""
set mailing_list_subcategory_id ""
set mailing_list_subsubcategory_id ""

if { [info exists user_id_list] } {
    set users_query "select user_id, email
    from users
    where user_id in ([join $user_id_list ", "])"
} elseif { [info exists mailing_list] } {
    if { [llength $mailing_list] == 0 } {
	set search_criteria "(category_id is null and subcategory_id is null and subsubcategory_id is null)"
    } elseif { [llength $mailing_list] == 1 } {
	set search_criteria "(category_id=$mailing_list and subcategory_id is null)"
	set mailing_list_category_id $mailing_list
    } elseif { [llength $mailing_list] == 2 } {
	set search_criteria "(subcategory_id=[lindex $mailing_list 2] and subsubcategory_id is null)"
	set mailing_list_category_id [lindex $mailing_list 0]
	set mailing_list_subcategory_id [lindex $mailing_list 1]
    } else {
	set search_criteria "subsubcategory_id=[lindex $mailing_list 3]"
	set mailing_list_category_id [lindex $mailing_list 0]
	set mailing_list_subcategory_id [lindex $mailing_list 1]
	set mailing_list_subsubcategory_id [lindex $mailing_list 2]
    }

    set users_query "select users.user_id, email
from users, ec_cat_mailing_lists
where users.user_id=ec_cat_mailing_lists.user_id
and $search_criteria"

} elseif { [info exists user_class_id] } {
    if { ![empty_string_p $user_class_id]} {
	set users_query "select users.user_id, first_names, last_name, email
	from users, ec_user_class_user_map m
	where m.user_class_id=$user_class_id
	and m.user_id=users.user_id"
    } else {
	set users_query "select user_id, first_names, last_name, email
	from users"
    }
} elseif { [info exists product_id] } {
    set users_query "select unique users.user_id, first_names, last_name, email
    from users, ec_items, ec_orders
    where ec_items.order_id=ec_orders.order_id
    and ec_orders.user_id=users.user_id
    and ec_items.product_id=$product_id"
} elseif { [info exists viewed_product_id] } {
    set users_query "select unique u.user_id, first_names, last_name, email
    from users u, ec_user_session_info ui, ec_user_sessions us
    where us.user_session_id=ui.user_session_id
    and us.user_id=u.user_id
    and ui.product_id=$viewed_product_id"
} elseif { [info exists category_id] } {
    set users_query "select unique u.user_id, first_names, last_name, email
    from users u, ec_user_session_info ui, ec_user_sessions us
    where us.user_session_id=ui.user_session_id
    and us.user_id=u.user_id
    and ui.category_id=$category_id"
} elseif { [info exists start_date] } {
    set users_query "select user_id, first_names, last_name, email
	from users
	where last_visit >= to_date('$start_date','YYYY-MM-DD HH24:MI:SS') and last_visit <= to_date('$end_date','YYYY-MM-DD HH24:MI:SS')"
}

# have to make all variables exist that will be inserted into ec_spam_log
if { ![info exists mailing_list_category_id] } {
    set mailing_list_category_id ""
}
if { ![info exists mailing_list_subcategory_id] } {
    set mailing_list_subcategory_id ""
}
if { ![info exists mailing_list_subsubcategory_id] } {
    set mailing_list_subsubcategory_id ""
}
if { ![info exists user_class_id] } {
    set user_class_id ""
}
if { ![info exists product_id] } {
    set product_id ""
}
if { ![info exists start_date] } {
    set start_date ""
}
if { ![info exists end_date] } {
    set end_date ""
}


ns_db dml $db "begin transaction"

ns_db dml $db "insert into ec_spam_log
(spam_id, spam_text, mailing_list_category_id, mailing_list_subcategory_id, mailing_list_subsubcategory_id, user_class_id, product_id, last_visit_start_date, last_visit_end_date)
values
($spam_id, '$QQmessage', '$mailing_list_category_id', '$mailing_list_subcategory_id', '$mailing_list_subsubcategory_id', '$user_class_id', '$product_id', to_date('$start_date','YYYY-MM-DD HH24:MI:SS'), to_date('$end_date','YYYY-MM-DD HH24:MI:SS'))
"

set selection [ns_db select $db $users_query]

ReturnHeaders
ns_write "[ad_admin_header "Spamming Users..."]
<h2>Spamming Users...</h2>

[ad_admin_context_bar [list "../index.tcl" "Ecommerce"] [list "index.tcl" "Customer Service Administration"] "Spamming Users..."]

<hr>
<ul>
"

while { [ns_db getrow $db $selection] } {
    set_variables_after_query

    # create a customer service issue/interaction/action
    set user_identification_and_issue_id [ec_customer_service_simple_issue $db_sub "" "automatic" "email" "[DoubleApos "To: $email\nFrom: [ad_parameter CustomerServiceEmailAddress ecommerce]\nSubject: $subject"]" "" $issue_type_list $message $user_id "f"]
    
    set user_identification_id [lindex $user_identification_and_issue_id 0]
    set issue_id [lindex $user_identification_and_issue_id 1]
    
    set email_from [ec_customer_service_email_address $user_identification_id $issue_id]
    
    ec_sendmail_from_service "$email" "$email_from" "$subject" "$message"

    if { ![empty_string_p $amount] && $amount > 0 } {
	# put a record into ec_gift_certificates
	# and add the amount to the user's gift certificate account

	ns_db dml $db_sub "insert into ec_gift_certificates
	(gift_certificate_id, user_id, amount, expires, issue_date, issued_by, gift_certificate_state, last_modified, last_modifying_user, modified_ip_address)
	values
	(ec_gift_cert_id_sequence.nextval, $user_id, $amount, $expires_to_insert, sysdate, $customer_service_rep, 'authorized', sysdate, $customer_service_rep, '[DoubleApos [ns_conn peeraddr]]')
	"
    }
    
    ns_write "<li>Email has been sent to $email\n"
}

ns_db dml $db "end transaction"

ns_write "</ul>

[ad_admin_footer]"

