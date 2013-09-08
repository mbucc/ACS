ad_page_contract {

    @param source_user_id
    @param target_user_id
    @author ?
    @creation-date ?
    @cvs-id merge-2.tcl,v 3.3.2.3.2.4 2000/09/22 01:36:27 kevin Exp
} {
    source_user_id:integer,notnull
    target_user_id:integer,notnull
}


# push all of source_user_id's content into target_user_id and drop 
# the source_user

db_1row source_user_info "select email as source_user_email, first_names as source_user_first_names, last_name as source_user_last_name, registration_date as source_user_registration_date, last_visit as source_user_last_visit
from users
where user_id = :source_user_id"

db_1row target_user_info "select email as target_user_email, first_names as target_user_first_names, last_name as target_user_last_name, registration_date as target_user_registration_date, last_visit as target_user_last_visit
from users
where user_id = :target_user_id"

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

db_transaction {

# let's just delete portals stuff

db_dml delete_portal_table_page_map "delete from portal_table_page_map 
where page_id in (select page_id from portal_pages where user_id = :source_user_id)"

db_dml delete_portal_pages "delete from portal_pages where user_id = :source_user_id"

append whole_page "<li>Deleted [db_resultrows] rows from the portal pages table.\n"

db_dml update_bboard "update bboard set user_id = :target_user_id where user_id = :source_user_id"

append whole_page "<li>Updated [db_resultrows] rows in the bboard table.\n"

db_dml update_chat_msgs_creation_user "update chat_msgs set creation_user = :target_user_id where creation_user = :source_user_id"

append whole_page "<li>Updated [db_resultrows] from rows in the chat table.\n"

db_dml update_chat_msgs_recipient_user "update chat_msgs set recipient_user = :target_user_id where recipient_user = :source_user_id"

append whole_page "<li>Updated [db_resultrows] to rows in the chat table.\n"

db_dml update_classified_ads "update classified_ads set user_id = :target_user_id where user_id = :source_user_id"

append whole_page "<li>Updated [db_resultrows] rows in the classified ads table.\n"

db_dml update_classified_email_alerts "update classified_email_alerts set user_id = :target_user_id where user_id = :source_user_id"

append whole_page "<li>Updated [db_resultrows] rows in the classified email alerts table.\n"

db_dml update_comments "update comments set user_id = :target_user_id where user_id = :source_user_id"

append whole_page "<li>Updated [db_resultrows] rows in the comments table.\n"

db_dml update_neighbor_to_neighbor "update neighbor_to_neighbor set poster_user_id = :target_user_id where poster_user_id = :source_user_id"

append whole_page "<li>Updated [db_resultrows] rows in the neighbor to neighbor table.\n"

db_dml update_links "update links set user_id = :target_user_id where user_id = :source_user_id"

append whole_page "<li>Updated [db_resultrows] rows in the links table.\n"

# don't want to violate the unique constraint, so get rid of duplicates first
db_dml delete_user_content_map "delete from user_content_map 
where user_id = :source_user_id 
and page_id in (select page_id from user_content_map where user_id = :target_user_id)"

db_dml update_user_content_map "update user_content_map 
set user_id = :target_user_id
where user_id = :source_user_id"

append whole_page "<li>Updated [db_resultrows] rows in the user_content_map table.\n"

# let's do the same thing for the user_curriculum_map
db_dml delete_user_curriculum_map "delete from user_curriculum_map
where user_id = :source_user_id 
and curriculum_element_id in (select curriculum_element_id from user_curriculum_map where user_id = :target_user_id)"

db_dml update_user_curriculum_map "update user_curriculum_map
set user_id = :target_user_id
where user_id = :source_user_id"

append whole_page "<li>Updated [db_resultrows] rows in the user_curriculum_map table.\n"

# now we have to do the same thing for the poll system

db_dml delete_poll_user_choices "delete from poll_user_choices
where (choice_id, user_id) in (select choice_id, user_id 
                               from poll_user_choices
                               where user_id = :target_user_id)"

db_dml update_poll_user_choices "update poll_user_choices
set user_id = :target_user_id
where user_id = :source_user_id"

append whole_page "<li>Updated [db_resultrows] rows in the poll_user_choices table.\n"

db_dml update_query_strings "update query_strings set user_id = :target_user_id where user_id = :source_user_id"

append whole_page "<li>Updated [db_resultrows] rows in the query_strings table.\n"

foreach entrants_table_name [db_list unused "select entrants_table_name from contest_domains"] {
    db_dml update_entrants_table_given_name "update $entrants_table_name set user_id = :target_user_id where user_id = :source_user_id"
    append whole_page "<li>Updated [db_resultrows] rows in the $entrants_table_name table.\n"
}

db_dml update_calendar "update calendar set creation_user = :target_user_id where creation_user = :source_user_id"
append whole_page "<li>Updated [db_resultrows] rows in the calendar table.\n"

db_dml update_general_comments "update general_comments set user_id = :target_user_id where user_id = :source_user_id"

append whole_page "<li>Updated [db_resultrows] rows in the general_comments table.\n"

db_dml update_stolen_registry "update stolen_registry set user_id = :target_user_id where user_id = :source_user_id"

append whole_page "<li>Updated [db_resultrows] rows in the stolen_registry table.\n"

# **** this must be beefed up so that we drop rows that would result
# **** in a duplicate mapping

# jeez -- just how lazy can you get? -- markc
               
db_dml update_user_group_map "
    update  
        user_group_map map
    set 
        user_id = :target_user_id 
    where 
        user_id = :source_user_id and
        not exists (
            select * from 
                user_group_map
            where
                user_id = :target_user_id and
                group_id = map.group_id and
                role = map.role
        )
"

                          

append whole_page "<li>Updated [db_resultrows] rows in the user_group_map table.\n"

# delete the duplicate mappings that we didn't transfer to the target user id

db_dml delete_user_group_map "delete from user_group_map where user_id = :source_user_id"

db_dml delete_email_log "delete from email_log where user_id = :source_user_id"

db_dml delete_users_preferences "delete from users_preferences where user_id = :source_user_id"
db_dml delete_users_interests "delete from users_interests where user_id = :source_user_id"
db_dml delete_user_requirements "delete from user_requirements where user_id = :source_user_id"
db_dml delete_users_demographics "delete from users_demographics where user_id = :source_user_id"
db_dml delete_users_contacts "delete from users_contact where user_id = :source_user_id"

# before we kill off old user, let's update registration date of new user

db_dml update_users_registration_date "update users 
set registration_date = (select min(registration_date) from users where user_id in (:target_user_id, :source_user_id))
where user_id = :target_user_id"

db_dml delete_users "delete from users where user_id = :source_user_id"

}

append whole_page "
</ul>

Done.

[ad_admin_footer]
"



doc_return  200 text/html $whole_page
