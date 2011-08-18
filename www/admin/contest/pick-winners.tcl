# $Id: pick-winners.tcl,v 3.1.2.1 2000/03/17 23:46:19 tzumainn Exp $
set_the_usual_form_variables

# domain_id, n_winners, AOLserver crud that adds up to from_date, to_date

page_validation {
    if {![info exists n_winners] || [empty_string_p $n_winners]} {
	error "Number of winners must be specified."
    }
}

ns_dbformvalue [ns_conn form] from_date date from_date
ns_dbformvalue [ns_conn form] to_date date to_date

set db [ns_db gethandle]

set selection [ns_db 1row $db "select unique * from contest_domains where domain_id='$QQdomain_id'"]
set_variables_after_query

set where_clause "where ct.entry_date between '$from_date' and to_date('$to_date 23:59:59','YYYY-MM-DD HH24:MI:SS')"

set n_contestants [database_to_tcl_string $db "select count(distinct user_id) 
from $entrants_table_name ct
$where_clause"]

# seed the random number generator
randomInit [ns_time]

for {set i 1} {$i <= $n_winners} {incr i} {
    # we'll have winner_numbers between 0 and $n_contestants - 1
    lappend winner_numbers [randomRange $n_contestants]
}

ReturnHeaders

ns_write "[ad_admin_header "Picking N winners"]

<h2>Picking N winners</h2>

[ad_admin_context_bar [list "index.tcl" "Contests"] [list "manage-domain.tcl?[export_url_vars domain_id]" "Manage Contest"] "Winners"]

<hr>


Found $n_contestants.  Winners will be $winner_numbers.


<ul>
"

set selection [ns_db select $db "select distinct user_id
from $entrants_table_name ct
$where_clause"]

set counter 0

while { [ns_db getrow $db $selection] } {
    if { [lsearch -exact $winner_numbers $counter] != -1 } {
	set_variables_after_query
	ns_write "<li><a href=\"show-one-winner.tcl?[export_url_vars user_id domain_id]\">User $user_id</a>\n"
    }
    incr counter
}

ns_write "</ul>

[ad_contest_admin_footer]"

