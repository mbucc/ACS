# /www/directory/lookup.tcl

ad_page_contract {
    diplays all the users that match either last name or email
    
    modified by flattop@arsdigita.com
    - got rid of setthe_usual_form_variables (1/28/00)
    - don't ns write after each row (3/10/00)

    @author berkeley@arsdigita.com
    @creation-date Tue Jul 11 14:52:18 2000
    @cvs-id lookup.tcl,v 3.5.2.9 2000/11/17 06:05:08 kevin Exp
    @param email An email address to search by
    @param last_name Someone's last name to search by
} {
    {email:trim {}} 
    {last_name:trim {}} 
} -validate {
    not_both_null -requires {email last_name} {
	if { [empty_string_p $email] && [empty_string_p $last_name] } {
	    ad_complain "Please type a query string in one of the boxes."
	}
    }

    wild_card_check -requires {not_both_null} {
	if {[string match "%" $email] || \
		[string match "%" $last_name]} {
	    ad_complain "\"%\" is a special character in our database.  You cannot include it in your search string."

	}
    }
}


set user_id [ad_maybe_redirect_for_registration]

set upper_email "[string toupper $email]%"
set upper_last_name "[string toupper $last_name]%"

#Some more complex checking
if { ![empty_string_p $last_name] && [empty_string_p $email] } {
    # we have a last name fragment but not an email address
    set description "whose last names begin with \"$last_name\""
    set where_clause "upper(last_name) like :upper_last_name"
    set order_by "upper(last_name), upper(first_names), upper(email)"
} elseif  { ![empty_string_p $email] && [empty_string_p $last_name] } {
    # we have an email fragment but not a last name
    set description "whose email address begins with \"$email\""
    set where_clause "upper(email) like :upper_email"
    set order_by "upper(email), upper(last_name), upper(first_names)"
} else {
    #must have gotten both
    set description "whose email address begins with \"$email\" OR whose last name begins with \"$last_name\""
    set where_clause "upper(email) like :upper_email or upper(last_name) like :upper_last_name"
    set order_by "upper(last_name), upper(first_names), upper(email)"
}

set simple_headline "<h2>Users</h2>

[ad_context_bar_ws_or_index [list "index" "User Directory"] "One Class"]

"

if ![empty_string_p [ad_parameter SearchResultsDecoration directory]] {
    set full_headline "<table cellspacing=10><tr><td>[ad_parameter SearchResultsDecoration directory]<td>$simple_headline</tr></table>"
} else {
    set full_headline $simple_headline
}


set body "
[ad_header "Users $description"]

$full_headline

<hr>

Class:  users $description
"





set list_items ""
set list_count 0

db_foreach search_results "select user_id, first_names, last_name, email
from  users
where ($where_clause)
and   user_state = 'authorized'
order by $order_by" {

    incr list_count
    if { ![empty_string_p $first_names] || ![empty_string_p $last_name] } {
	set full_name "$first_names $last_name"
    } else {
	set full_name "name unknown"
    }
    append list_items "<li><a href=\"/shared/community-member?user_id=$user_id\">$full_name</a> (<a href=\"mailto:$email\">$email</a>)\n"
}

db_release_unused_handles 

if { $list_count == 0 } {
    set list_items "<li>There are currently no matches in the database."
}

append body "
<ul>
$list_items
</ul>

<i>Note: The only reason you are seeing this page at all is that you
are a logged-in authenticated user of [ad_system_name]; this
information is not available to tourists.</i>

[ad_footer]
"
doc_return  200 text/html $body








