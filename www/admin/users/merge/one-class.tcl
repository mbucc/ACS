ad_page_contract {
    @cvs-id one-class.tcl,v 3.3.2.3.2.4 2000/09/22 01:36:28 kevin Exp

    we get a form that specifies a class of user, plus maybe an order_by
    spec
} {
    {order_by ""}
}
# to do: what are the form variables here???


set description [ad_user_class_description [ns_getform]]

# we have to delete order_by from the form or the export_entire_form_as_url_vars
# below won't work

ns_set delkey [ns_getform] order_by

if { $order_by == "email" } {
    set order_by_clause "upper(email), upper(last_name), upper(first_names)"
    set option "<a href=\"one-class?order_by=last_name&[export_entire_form_as_url_vars]\">sort by last name</a> | <a href=\"one-class?order_by=first_names&[export_entire_form_as_url_vars]\">sort by first name</a>"
} elseif { $order_by == "first_names" } {
    set order_by_clause "upper(first_names), upper(last_name), upper(email)"
    set option "<a href=\"one-class?order_by=email&[export_entire_form_as_url_vars]\">sort by email</a> | <a href=\"one-class?order_by=last_name&[export_entire_form_as_url_vars]\">sort by last name</a>"
} else {
    set order_by_clause "upper(last_name), upper(first_names), upper(email)"
    set option "<a href=\"one-class?order_by=email&[export_entire_form_as_url_vars]\">sort by email</a> | <a href=\"one-class?order_by=first_names&[export_entire_form_as_url_vars]\">sort by first name</a>"
}

append whole_page "[ad_admin_header "Candidates for Merger"]

<h2>Candidates for Merger</h2>

among $description ordered by $order_by

<hr>

$option

<ul>

"

set query [ad_user_class_query [ns_conn form]]
append ordered_query $query "\n" "order by $order_by_clause"

set last_id ""
db_foreach ordered_users $ordered_query {
    append whole_page "<li><a target=new_window href=\"../one?user_id=$user_id\">"
    if { $order_by == "email" } {
	append whole_page "$email</a> ($first_names $last_name)"
    } else {
	append whole_page "$first_names $last_name</a> ($email)"	
    }
    if ![empty_string_p $last_id] {
	append whole_page " <a target=merge_window href=\"merge?u1=$last_id&u2=$user_id\"><font size=-1>merge with above</font></a>\n"
    }
    set last_id $user_id
}

append whole_page "

</ul>

[ad_admin_footer]
"



doc_return  200 text/html $whole_page
