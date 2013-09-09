# /www/bboard/admin-community-pick.tcl
ad_page_contract {
    Randomly picks some people

    @param topic the name of the forum we are picking posters from
    @param topic_id the ID of the bboard forum
    @param n_postings the minimum number of postings to qualify
    @param n_winners the number of people to pick
    
    @cvs-id admin-community-pick.tcl,v 3.2.2.4 2000/09/22 01:36:43 kevin Exp
} {
    topic:notnull
    topic_id:integer,notnull
    n_postings:integer
    start_date:date,array
    end_date:date,array
    n_winners:integer
}

# -----------------------------------------------------------------------------

if  {[bboard_get_topic_info] == -1} {
    return
}

if {[bboard_admin_authorization] == -1} {
    return
}


# cookie checks out; user is authorized



append page_content "
[bboard_header "Picking random participants in $topic forum"]

<h2>Pick random participants in $topic forum</h2>

(<a href=\"admin-home?[export_url_vars topic topic_id]\">main admin page</a>)

<hr>

Querying the database for participants who've made at least
$n_postings postings between $start_date(date) and $end_date(date) ...

<P>

<ul>

"

set ora_start $start_date(date)
set ora_end   $end_date(date)

if { $n_postings < 2 } {
    set sql "
    select distinct bboard.user_id, 
    	   email, 
    	   upper(email) as upper_email, 
    	   count(bboard.user_id) as how_many_posts
    from   bboard, users 
    where  bboard.user_id = users.user_id
    and    topic_id = :topic_id
    and    posting_time >= to_date(:ora_start,'YYYY-MM-DD')
    and    posting_time <= to_date(:ora_end,'YYYY-MM-DD')
    group by bboard.user_id, email
    order by upper_email"

} else {

    set sql "
    select distinct email, 
    	   upper(email) as upper_email, 
    	   count(*) as how_many_posts
    from   bboard, users
    where  bboard.user_id = users.user_id
    and    topic_id = :topic_id
    and    posting_time >= to_date(:ora_start,'YYYY-MM-DD')
    and    posting_time <= to_date(:ora_end,'YYYY-MM-DD')
    and    bboard.user_id = users.user_id
    group by email
    having count(*) >= :n_postings
    order by upper_email"
}

set last_upper_email ""
set distinct_emails [ns_set new distinct_emails]

# let's build up an ns_set so that we don't give unfair advantage
# to people who vary their capitalization

db_foreach candidates $sql {

    if { $last_upper_email != $upper_email } {
	ns_set put $distinct_emails $email $how_many_posts
    } 
    set last_upper_email $upper_email
}

set n_users [ns_set size $distinct_emails]

if { $n_users < $n_winners } {
    append page_content "You asked for $n_winners winners but there are only $n_users distinct people who meet the date and number of postings constraints."
} else {
    # enough people
    # seed the random number generator
    randomInit [ns_time]
    for {set i 1} {$i <= $n_winners} {incr i} {
	# we'll have winner_numbers between 0 and 1-$n_contestants
	set winning_index [randomRange [ns_set size $distinct_emails]]
	set winner_email_address [ns_set key $distinct_emails $winning_index]
	set winner_n_postings [ns_set value $distinct_emails $winning_index]
	append page_content "<li>picked <a href=\"admin-view-one-email?email=[ns_urlencode $winner_email_address]&[export_url_vars topic topic_id]\">$winner_email_address</a> ($winner_n_postings postings)\n"
	ns_set delete $distinct_emails $winning_index
    }
}



append page_content "</ul>

[bboard_footer]
"



doc_return  200 text/html $page_content