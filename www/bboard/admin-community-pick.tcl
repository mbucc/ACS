# $Id: admin-community-pick.tcl,v 3.0 2000/02/06 03:32:40 ron Exp $
set_form_variables_string_trim_DoubleAposQQ
set_form_variables

# topic, topic_id, n_postings, start_date, end_date, n_winners


set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}

if  {[bboard_get_topic_info] == -1} {
    return}

if {[bboard_admin_authorization] == -1} {
	return}



# cookie checks out; user is authorized


ReturnHeaders

ns_write "<html>
<head>
<title>Picking random participants in $topic forum</title>
</head>
<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>

<h2>Pick random participants in $topic forum</h2>

(<a href=\"admin-home.tcl?[export_url_vars topic topic_id]\">main admin page</a>)

<hr>

Querying the database for participants who've made at least
$n_postings postings between $start_date and $end_date...

<P>

<ul>

"

if { $n_postings < 2 } {
    set sql "select distinct bboard.user_id, email, upper(email) as upper_email, count(bboard.user_id) as how_many_posts
from bboard, users 
where bboard.user_id = users.user_id
and topic_id = $topic_id
and posting_time >= to_date('$start_date','YYYY-MM-DD')
and posting_time <= to_date('$end_date','YYYY-MM-DD')
group by bboard.user_id, email
order by upper_email"
} else {
    set sql "select distinct email, upper(email) as upper_email, count(*) as how_many_posts
from bboard, users
and topic_id = $topic_id
and posting_time >= to_date('$start_date','YYYY-MM-DD')
and posting_time <= to_date('$end_date','YYYY-MM-DD')
and bboard.user_id = users.user_id
group by email
having count(*) >= $n_postings
order by upper_email"
}

set selection [ns_db select $db $sql]

set last_upper_email ""
set distinct_emails [ns_set new distinct_emails]

# let's build up an ns_set so that we don't give unfair advantage
# to people who vary their capitalization

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { $last_upper_email != $upper_email } {
	ns_set put $distinct_emails $email $how_many_posts
    } 
    set last_upper_email $upper_email
}

set n_users [ns_set size $distinct_emails]

if { $n_users < $n_winners } {
    ns_write "You asked for $n_winners winners but there are only $n_users distinct people who meet the date and number of postings constraints."
} else {
    # enough people
    # seed the random number generator
    randomInit [ns_time]
    for {set i 1} {$i <= $n_winners} {incr i} {
	# we'll have winner_numbers between 0 and 1-$n_contestants
	set winning_index [randomRange [ns_set size $distinct_emails]]
	set winner_email_address [ns_set key $distinct_emails $winning_index]
	set winner_n_postings [ns_set value $distinct_emails $winning_index]
	ns_write "<li>picked <a href=\"admin-view-one-email.tcl?email=[ns_urlencode $winner_email_address]&[export_url_vars topic topic_id]\">$winner_email_address</a> ($winner_n_postings postings)\n"
	ns_set delete $distinct_emails $winning_index
    }
}



ns_write "</ul>

[bboard_footer]
"
