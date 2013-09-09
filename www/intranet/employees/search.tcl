# /www/intranet/employees/search.tcl

ad_page_contract {
    Allows you to search through all employees

    @param search_type Search|'Feeling Lucky' - If Feeling Lucky
    (case-insensitive match), we redirect to the first match found

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000

    @cvs-id search.tcl,v 3.15.2.8 2000/09/22 01:38:31 kevin Exp
} {
    { keywords "" }
    { target "" }
    { search_type "Search" }
}

set search_type [string toupper [string trim $search_type]]

if { [empty_string_p [string trim $keywords]] } {
    # Show all employees
    ad_returnredirect index
    return
}

if { [empty_string_p $target] } {
    set target "../users/view"
}

# Get target ready to use
if { [regexp {\?} $target] } {
    append target "&"
} else {
    append target "?"
}

set upper_keywords [string toupper [string trim $keywords]]
# Convert * to oracle wild card
regsub -all {\*} $upper_keywords {%} upper_keywords

set upper_keywords "%$upper_keywords%"

# Search everyone, but list employees first

set list_everyone_sql "
        select u.last_name || ', ' || u.first_names as full_name, email, u.user_id,
                ad_group_member_p(u.user_id, [im_employee_group_id]) as employee_p
           from users_active u, users_contact uc
          where upper(u.last_name||' '||u.first_names||' '||u.last_name||' '||u.email||' '||uc.aim_screen_name||' '||u.screen_name) like (:upper_keywords)
            and u.user_id=uc.user_id(+)
          order by employee_p desc, lower(trim(full_name))"

set number 0
set results ""
set last_employee_p ""

db_foreach list_everyone $list_everyone_sql {
    incr number    
    if { $employee_p == "t" } {
	set url "$target[export_url_vars user_id]"
    } else {
	set url "/shared/community-member?[export_url_vars user_id]"
	
    }

    if { $number == 1 && [string compare $search_type "FEELING LUCKY"] == 0 } {
	db_release_unused_handles
	ad_returnredirect $url
	# Let's bail out of here...
	ad_script_abort
    }
    if { [string compare $employee_p $last_employee_p] != 0 } {
	if { ![empty_string_p $last_employee_p] } {
	    append results "</ul>\n"
	}
	append results "<h3>[util_decode $employee_p "t" "Employees" "Community members"]</h3><ul>\n"
	set last_employee_p $employee_p
    }

    append results "  <li> <a href=$url>$full_name</a>"
    if { ![empty_string_p $email] } {
        append results " &lt;<a href=\"mailto:$email\">$email</a>&gt;"
    }
    append results "\n"
}

db_release_unused_handles

if { [empty_string_p $results] } {
    set page_body "
<blockquote>
<b>No matches found.</b>
Look at all <a href=index>employees</a>
</blockquote>
"
} else {
    append results "</ul>\n"
    set page_body "
<b>[util_commify_number $number] [util_decode $number 1 "match was" "matches were"] found</b>
$results

"
}

set page_title "User and Employee Search"
set context_bar [ad_context_bar_ws [list ./ "Employees"] Search]

doc_return  200 text/html [im_return_template]
