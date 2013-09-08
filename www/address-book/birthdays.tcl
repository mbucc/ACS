# /www/address-book/birthdays.tcl

ad_page_contract {

    shows al the birthdays

    @param scope
    @param user_id
    @param group_id
    @param contact_info_only
    @param order_by

    @cvs-id birthdays.tcl,v 3.2.2.12 2000/10/10 14:46:34 luke Exp
    @creation-date 12/24/99
    @author teadams@arsdigita.com
    @author tarik@arsdigita.com

} {
    user_id:optional,integer
    group_id:optional,integer
    scope:optional
    contact_info_only:optional
    order_by:optional
}
    
ad_scope_error_check user

ad_scope_authorize $scope none group_member user

set name [address_book_name]

set page_content "
[ad_scope_header "Birthdays"]
[ad_scope_page_title "Birthdays"]
[ad_scope_context_bar_ws [list "index?[export_url_scope_vars]" "Address book"] "Birthdays"]
<hr>
[ad_scope_navbar]
<blockquote>
"

# this is for my ordering scheme described below
set date_format "MMDDYYYY"
set this_year   [db_string birth_year "select to_char(sysdate,'YYYY') from dual"]
set a_leap_year "1996"
set this_date_in_a_leap_year \
	[concat [db_string leap_year "select to_char(sysdate, 'MMDD') from dual"] $a_leap_year]

# the crazy-looking ordering below was chosen so that if someone's
# birthday is today, it will show up first, then we'll see people who
# have birthdays coming up this year (in chronological order), then
# we'll see people whose next birthday won't be until next year (in
# chronological order)  

db_foreach address_book_birthday_loop "
    select address_book_id, 
           first_names, 
           last_name, 
           birthmonth, 
           birthday, 
           birthyear, 
           sign(to_date(:this_date_in_a_leap_year,:date_format)-to_date(birthmonth || birthday || :a_leap_year,:date_format)) as before_or_after_today, 
           to_char(to_date(birthmonth,'MM'),'Mon') as pretty_birthmonth
    from   address_book 
    where  [ad_scope_sql] and birthmonth is not null
    order by 
          abs(sign(to_date(:this_date_in_a_leap_year,:date_format)-to_date(birthmonth || birthday || :a_leap_year,:date_format))),
          sign(to_date(:this_date_in_a_leap_year,:date_format)-to_date(birthmonth || birthday || :a_leap_year,:date_format)),
    to_date(birthmonth || birthday ||
:a_leap_year,:date_format)-to_date(:this_date_in_a_leap_year,:date_format)" {

    # if $before_or_after_today = -1 then the birthday is later in
    # the year than today, if it's 0 then it's today, if 1 then it
    # won't occur until next year  
    
    append page_content "$pretty_birthmonth $birthday: 
    <a href=record?[export_url_scope_vars address_book_id]>$first_names $last_name</a>"
    
    if ![empty_string_p $birthyear] {
	if { $before_or_after_today == 0 } {
	    set age_on_next_birthday [expr $this_year - $birthyear]
	    append page_content " (turns $age_on_next_birthday today!)"
	} elseif { $before_or_after_today == -1 } {
	    set age_on_next_birthday [expr $this_year - $birthyear]
	    append page_content " (turns $age_on_next_birthday)"
	} else {
	    set age_on_next_birthday [expr $this_year + 1 - $birthyear]
	    append page_content " (turns $age_on_next_birthday)"
	}
    }
    
    append page_content "<br>"
} if_no_rows {
    append page_content "<p>No birthdays have been entered."
}


append page_content "
</blockquote>
[ad_scope_footer]
"

doc_return  200 text/html $page_content








