# $Id: merge-2.tcl,v 3.2 2000/03/09 00:01:38 scott Exp $
set_the_usual_form_variables

# source_user_id, target_user_id

# push all of source_user_id's content into target_user_id and drop 
# the source_user

set db_conns [ns_db gethandle [philg_server_default_pool] 2]
set db [lindex $db_conns 0]
set db_sub [lindex $db_conns 1]

set selection [ns_db 1row $db "select email as source_user_email, first_names as source_user_first_names, last_name as source_user_last_name, registration_date as source_user_registration_date, last_visit as source_user_last_visit
from users
where user_id = $source_user_id"]
set_variables_after_query

set selection [ns_db 1row $db "select email as target_user_email, first_names as target_user_first_names, last_name as target_user_last_name, registration_date as target_user_registration_date, last_visit as target_user_last_visit
from users
where user_id = $target_user_id"]
set_variables_after_query


append whole_page "[ad_admin_header "Merging $source_user_email into $target_user_email"]

<h2>Merging</h2>

$source_user_email into $target_user_email

<hr>

All of the content contributed by User ID $source_user_id 
($source_user_first_names $source_user_last_name; $source_user_email)
will be reattributed to User ID $target_user_id
($target_user_first_names $target_user_last_name; $target_user_email).

<p>

Then we will drop  User ID $source_user_id.

<p>

<blockquote>

<i><font size=-1>All of this happens inside an RDBMS transaction.  If
there is an error during any part of this process, the database is
left untouched.</font>
</i>
</blockquote>

<ul>

"

ns_db dml $db "begin transaction"

# let's just delete portals stuff

ns_db dml $db "delete from portal_table_page_map 
where page_id in (select page_id from portal_pages where user_id = $source_user_id)"

ns_db dml $db "delete from portal_pages where user_id = $source_user_id"

append whole_page "<li>Deleted [ns_ora resultrows $db] rows from the portal pages table.\n"


ns_db dml $db "update bboard set user_id = $target_user_id where user_id = $source_user_id"

append whole_page "<li>Updated [ns_ora resultrows $db] rows in the bboard table.\n"

ns_db dml $db "update chat_msgs set creation_user = $target_user_id where creation_user = $source_user_id"

append whole_page "<li>Updated [ns_ora resultrows $db] from rows in the chat table.\n"

ns_db dml $db "update chat_msgs set recipient_user = $target_user_id where recipient_user = $source_user_id"

append whole_page "<li>Updated [ns_ora resultrows $db] to rows in the chat table.\n"


ns_db dml $db "update classified_ads set user_id = $target_user_id where user_id = $source_user_id"

append whole_page "<li>Updated [ns_ora resultrows $db] rows in the classified ads table.\n"

ns_db dml $db "update classified_email_alerts set user_id = $target_user_id where user_id = $source_user_id"

append whole_page "<li>Updated [ns_ora resultrows $db] rows in the classified email alerts table.\n"

ns_db dml $db "update comments set user_id = $target_user_id where user_id = $source_user_id"

append whole_page "<li>Updated [ns_ora resultrows $db] rows in the comments table.\n"

ns_db dml $db "update neighbor_to_neighbor set poster_user_id = $target_user_id where poster_user_id = $source_user_id"

append whole_page "<li>Updated [ns_ora resultrows $db] rows in the neighbor to neighbor table.\n"

ns_db dml $db "update links set user_id = $target_user_id where user_id = $source_user_id"

append whole_page "<li>Updated [ns_ora resultrows $db] rows in the links table.\n"

# don't want to violate the unique constraint, so get rid of duplicates first
ns_db dml $db "delete from user_content_map 
where user_id = $source_user_id 
and page_id in (select page_id from user_content_map where user_id = $target_user_id)"

ns_db dml $db "update user_content_map 
set user_id = $target_user_id
where user_id = $source_user_id"

append whole_page "<li>Updated [ns_ora resultrows $db] rows in the user_content_map table.\n"

# let's do the same thing for the user_curriculum_map
ns_db dml $db "delete from user_curriculum_map
where user_id = $source_user_id 
and curriculum_element_id in (select curriculum_element_id from user_curriculum_map where user_id = $target_user_id)"

ns_db dml $db "update user_curriculum_map
set user_id = $target_user_id
where user_id = $source_user_id"

append whole_page "<li>Updated [ns_ora resultrows $db] rows in the user_curriculum_map table.\n"

# now we have to do the same thing for the poll system

ns_db dml $db "delete from poll_user_choices
where (choice_id, user_id) in (select choice_id, user_id 
                               from poll_user_choices
                               where user_id = $target_user_id)"


ns_db dml $db "update poll_user_choices
set user_id = $target_user_id
where user_id = $source_user_id"

append whole_page "<li>Updated [ns_ora resultrows $db] rows in the poll_user_choices table.\n"


ns_db dml $db "update query_strings set user_id = $target_user_id where user_id = $source_user_id"

append whole_page "<li>Updated [ns_ora resultrows $db] rows in the query_strings table.\n"


foreach entrants_table_name [database_to_tcl_list $db_sub "select entrants_table_name from contest_domains"] {
    ns_db dml $db "update $entrants_table_name set user_id = $target_user_id where user_id = $source_user_id"
    append whole_page "<li>Updated [ns_ora resultrows $db] rows in the $entrants_table_name table.\n"
}

ns_db dml $db "update calendar set creation_user = $target_user_id where creation_user = $source_user_id"
append whole_page "<li>Updated [ns_ora resultrows $db] rows in the calendar table.\n"

ns_db dml $db "update general_comments set user_id = $target_user_id where user_id = $source_user_id"

append whole_page "<li>Updated [ns_ora resultrows $db] rows in the general_comments table.\n"

ns_db dml $db "update stolen_registry set user_id = $target_user_id where user_id = $source_user_id"

append whole_page "<li>Updated [ns_ora resultrows $db] rows in the stolen_registry table.\n"

# **** this must be beefed up so that we drop rows that would result
# **** in a duplicate mapping

# jeez -- just how lazy can you get? -- markc
               
ns_db dml $db "
    update  
        user_group_map map
    set 
        user_id = $target_user_id 
    where 
        user_id = $source_user_id and
        not exists (
            select * from 
                user_group_map
            where
                user_id = $target_user_id and
                group_id = map.group_id and
                role = map.role
        )
"

                          

append whole_page "<li>Updated [ns_ora resultrows $db] rows in the user_group_map table.\n"

# delete the duplicate mappings that we didn't transfer to the target user id

ns_db dml $db "delete from user_group_map where user_id = $source_user_id"


ns_db dml $db "delete from email_log where user_id = $source_user_id"

ns_db dml $db "delete from users_preferences where user_id = $source_user_id"
ns_db dml $db "delete from users_interests where user_id = $source_user_id"
ns_db dml $db "delete from user_requirements where user_id = $source_user_id"
ns_db dml $db "delete from users_demographics where user_id = $source_user_id"
ns_db dml $db "delete from users_contact where user_id = $source_user_id"

# before we kill off old user, let's update registration date of new user

ns_db dml $db "update users 
set registration_date = (select min(registration_date) from users where user_id in ($target_user_id, $source_user_id))
where user_id = $target_user_id"

ns_db dml $db "delete from users where user_id = $source_user_id"

ns_db dml $db "end transaction"

append whole_page "
</ul>

Done.

[ad_admin_footer]
"
ns_db releasehandle $db
ns_db releasehandle $db_sub
ns_return 200 text/html $whole_page
