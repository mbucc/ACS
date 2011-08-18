# $Id: lookup.tcl,v 3.1.2.1 2000/04/28 15:09:55 carsten Exp $
# /directory/lookup.tcl
#
# diplays all the users that match either last name or email
#
# modified by flattop@arsdigita.com
#  - got rid of set_the_usual_form_variables (1/28/00)
#  - don't ns_write after each row (3/10/00)

ad_page_variables { {email {}} {last_name {}} }

# just in case user press a space bar in text box
set email [string trim $email]
set last_name [string trim $last_name]

set user_id [ad_verify_and_get_user_id]

if { $user_id == 0 } {
    ad_returnredirect "/register/index.tcl?return_url=[ns_urlencode "/directory/"]"
    return
}

if { ![empty_string_p $last_name] && [empty_string_p $email] } {
    # we have a last name fragment but not an email address
    set description "whose last names begin with \"$last_name\""
    set where_clause "upper(last_name) like '[DoubleApos [string toupper $last_name]]%'"
    set order_by "upper(last_name), upper(first_names), upper(email)"
} elseif  { ![empty_string_p $email] && [empty_string_p $last_name] } {
    # we have an email fragment but not a last name
    set description "whose email address begins with \"$email\""
    set where_clause "upper(email) like '[DoubleApos [string toupper $email]]%'"
    set order_by "upper(email), upper(last_name), upper(first_names)"
} elseif { ![empty_string_p $last_name] && ![empty_string_p $email] } {
    set description "whose email address begins with \"$email\" OR whose last name begins with \"$last_name\""
    set where_clause "upper(email) like '[DoubleApos [string toupper $email]]%' or upper(last_name) like '[DoubleApos [string toupper $last_name]]%'"
    set order_by "upper(last_name), upper(first_names), upper(email)"
} else {
    # we've got neither
    ad_return_complaint 1 "<li>please type a query string in one of the boxes."
    return
}

set simple_headline "<h2>Users</h2>

[ad_context_bar_ws_or_index [list "index.tcl" "User Directory"] "One Class"]

"

if ![empty_string_p [ad_parameter SearchResultsDecoration directory]] {
    set full_headline "<table cellspacing=10><tr><td>[ad_parameter SearchResultsDecoration directory]<td>$simple_headline</tr></table>"
} else {
    set full_headline $simple_headline
}


ReturnHeaders

ns_write "
[ad_header "Users $description"]

$full_headline

<hr>

Class:  users $description
"

set db [ns_db gethandle]

set selection [ns_db select $db "select user_id, first_names, last_name, email
from users
where $where_clause
order by $order_by"]

set list_items ""
set list_count 0

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    incr list_count
    if { ![empty_string_p $first_names] || ![empty_string_p $last_name] } {
	set full_name "$first_names $last_name"
    } else {
	set full_name "name unknown"
    }
    append list_items "<li><a href=\"/shared/community-member.tcl?user_id=$user_id\">$full_name</a> (<a href=\"mailto:$email\">$email</a>)\n"
}

ns_db releasehandle $db 

if { $list_count == 0 } {
    set list_items "<li>There are currently no matches in the database."
}

ns_write "
<ul>
$list_items
</ul>

<i>Note: The only reason you are seeing this page at all is that you
are a logged-in authenticated user of [ad_system_name]; this
information is not available to tourists.</i>

[ad_footer]
"
