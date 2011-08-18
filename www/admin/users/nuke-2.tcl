# $Id: nuke-2.tcl,v 3.0.4.3 2000/03/16 18:22:24 lars Exp $
set_form_variables

# user_id

set db [ns_db gethandle]

# Uncomment this when there's a real orders table or system in place!
# set selection [ns_db 0or1row $db "select count(*) as n_orders 
#	from user_orders where user_id = $user_id"]
# set_variables_after_query
set n_orders 0

# Don't nuke anyone who pays us money ...
if { $n_orders > 0 } {
    ad_return_error "Can't Nuke a Paying Customer" "We can't nuke a paying customer because to do so would screw up accounting records."
    return
}

# have no mercy on the freeloaders

# if this fails, it will probably be because the installation has 
# added tables that reference the users table

with_transaction $db {

    # bboard system
    ns_db dml $db "delete from bboard_email_alerts where user_id=$user_id"
    ns_db dml $db "delete from bboard_thread_email_alerts where user_id = $user_id"
    
    # deleting from bboard is hard because we have to delete not only a user's
    # messages but also subtrees that refer to them
    bboard_delete_messages_and_subtrees_where $db "user_id=$user_id"
    
    # let's do the classifieds now
    ns_db dml $db "delete from classified_auction_bids where user_id=$user_id"
    ns_db dml $db "delete from classified_ads where user_id=$user_id"
    ns_db dml $db "delete from classified_email_alerts where user_id=$user_id"
    ns_db dml $db "delete from general_comments 
 where on_which_table = 'neighbor_to_neighbor'
 and on_what_id in (select neighbor_to_neighbor_id 
                   from neighbor_to_neighbor 
                   where poster_user_id = $user_id)"
    ns_db dml $db "delete from neighbor_to_neighbor where poster_user_id = $user_id"
    # now the calendar
    ns_db dml $db "delete from calendar where creation_user=$user_id"
    # contest tables are going to be tough
    set all_contest_entrants_tables [database_to_tcl_list $db "select entrants_table_name from contest_domains"]
    foreach entrants_table $all_contest_entrants_tables {
	ns_db dml $db "delete from $entrants_table where user_id = $user_id"
    }

    # spam history
    ns_db dml $db "delete from spam_history where creation_user=$user_id"
    ns_db dml $db "update spam_history set last_user_id_sent = NULL
                    where last_user_id_sent=$user_id"

    # calendar
    ns_db dml $db "delete from calendar_categories where user_id=$user_id"

    # sessions
    ns_db dml $db "delete from sec_sessions where user_id=$user_id"
    ns_db dml $db "delete from sec_login_tokens where user_id=$user_id"
    
    # general stuff
    ns_db dml $db "delete from general_comments where user_id=$user_id"
    ns_db dml $db "delete from comments where user_id=$user_id"
    ns_db dml $db "delete from links where user_id=$user_id"
    ns_db dml $db "delete from chat_msgs where creation_user=$user_id"
    ns_db dml $db "delete from query_strings where user_id=$user_id"
    ns_db dml $db "delete from user_curriculum_map where user_id=$user_id"
    ns_db dml $db "delete from user_content_map where user_id=$user_id"
    ns_db dml $db "delete from user_group_map where user_id=$user_id"

    # core tables
    ns_db dml $db "delete from users_interests where user_id=$user_id"
    ns_db dml $db "delete from users_charges where user_id=$user_id"
    ns_db dml $db "update users_demographics set referred_by = null where referred_by = $user_id"
    ns_db dml $db "delete from users_demographics where user_id=$user_id"
    ns_db dml $db "delete from users_preferences where user_id=$user_id"
    ns_db dml $db "delete from users_contact where user_id=$user_id"
    ns_db dml $db "delete from users where user_id=$user_id"
} {
    
    set detailed_explanation ""

    if {[ regexp {integrity constraint \([^.]+\.([^)]+)\)} $errmsg match constraint_name]} {
	
	set selection [ns_db select $db "select table_name from user_constraints 
	where constraint_name='[DoubleApos $constraint_name]'"]

	if {[ns_db getrow $db $selection]} {
	    set_variables_after_query
	    set detailed_explanation "<p>
	    It seems the table we missed is $table_name."
	}
    }

    ad_return_error "Failed to nuke" "The nuking of user $user_id failed.  Probably this is because your installation of the ArsDigita Community System has been customized and there are new tables that reference the users table.  Complain to your programmer!  

$detailed_explanation

<p>

For good measure, here's what the database had to say...

<blockquote>
<pre>
$errmsg
</pre>
</blockquote>"
    return
}

ns_return 200 text/html "[ad_admin_header "Done"]

<h2>Done</h2>

<hr>

We've nuked user $user_id.  You can <a href=\"/admin/users/\">return
to user administration</a> now.

[ad_admin_footer]
"
