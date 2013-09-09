# /www/admin/contest/pick-winners.tcl
ad_page_contract {
    Pick the winners of the contest.

    @param domain_id which contest this is
    @param n_winners the number of winners
    @param from_date the from_date
    @param to_date the to_date

    @author mbryzek@arsdigita.com
    @cvs-id pick-winners.tcl,v 3.4.2.8 2000/09/22 01:34:36 kevin Exp
} {
    domain_id:integer
    {n_winners:integer 1}
    from_date:array
    to_date:array
}

#  page_validation {
#      if {[catch {set from_date [validate_ad_dateentrywidget from_date from_date [ns_conn form]]} errmsg]} { 
#  	error "Bad explicit from_date: $errmsg"
#      }
#      if {[catch {set to_date [validate_ad_dateentrywidget to_date to_date [ns_conn form]]} errmsg]} { 
#  	error "Bad explicit to_date: $errmsg"
#      }
#  }

set start_date $from_date(year)-$from_date(month)-$from_date(day)
set end_date   $to_date(year)-$to_date(month)-$to_date(day)

#make sure the dates are valid
page_validation {
    set errmsg ""
    set date_flag 1

    if {[catch {db_string contest_check_start "select
    to_date(:start_date) as start_date_check from dual"} err]} {
	append errmsg "<li>Your start date is not valid"
	set date_flag 0
    }

    if {[catch {db_string contest_check_end "select
    to_date(:end_date) as start_date_check from dual"} err]} {
	append errmsg "<li>Your end date is not valid"
	set date_flag 0
    }

    if {$date_flag == 1} {
	set date_check [db_string contest_check_dates "select
	count(*) from dual
	where to_date(:end_date) < to_date(:start_date)"]

	if {$date_check > 0} {
	    append errmsg "<li>Your end date cannot be before your start date"
	}
    }

    if {![empty_string_p $errmsg]} {
	error $errmsg
    }
}


db_1row all_contest_info "select unique domain, entrants_table_name from contest_domains where domain_id = :domain_id"

#set to_date "[lindex [array get to_date date] 1] 23:59:59"
#set from_date [lindex [array get from_date date 1]]

set n_contestants [db_string n_contestants "select count(distinct user_id) 
from $entrants_table_name ct
where ct.entry_date between to_date(:start_date,'YYYY-MM-DD') and to_date(:end_date,'YYYY-MM-DD')"]

# seed the random number generator
randomInit [ns_time]

set winner_numbers [list]

for {set i 1} {$i <= $n_winners} {incr i} {
    # we'll have winner_numbers between 0 and $n_contestants - 1
    lappend winner_numbers [randomRange $n_contestants]
}


set page_content "[ad_admin_header "Picking N winners"]

<h2>Picking N winners</h2>

[ad_admin_context_bar [list "index.tcl" "Contests"] [list "manage-domain.tcl?[export_url_vars domain_id]" "Manage Contest"] "Winners"]

<hr>

Found $n_contestants.  Winners will be $winner_numbers.

<ul>
"

set counter 0

db_foreach contest_entrants "
    select distinct user_id
    from $entrants_table_name ct
    where ct.entry_date between to_date(:start_date,'YYYY-MM-DD') and to_date(:end_date,'YYYY-MM-DD')
" {

    # between :from_date and to_date(:to_date,'YYYY-MM-DD HH24:MI:SS')"

    if { [lsearch -exact $winner_numbers $counter] != -1 } {
	append page_content "<li><a href=\"show-one-winner?[export_url_vars user_id domain_id]\">User $user_id</a>\n"
    }

    incr counter
}

append page_content "</ul>

[ad_contest_admin_footer]"



doc_return  200 text/html $page_content