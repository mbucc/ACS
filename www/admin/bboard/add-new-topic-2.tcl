# /www/admin/bboard/add-new-topic-2.tcl
ad_page_contract {
    Processes the new topic.

    @param topic the name of the new topic
    @param user_id_from_search the ID of the maintainer
    @param presentation_type the type of bboard (threaded, Q&A, etc)
    @param moderation_policy how the bboard is moderated
    @param notify_of_new_postings_p is the maintainer notified of all postings?
    @param group_id Group with which to associate this topic

    $cvs-id add-new-topic-2.tcl,v 3.4.2.6 2000/09/22 01:34:20 kevin Exp
} {
    topic:notnull
    user_id_from_search:integer,notnull
    presentation_type
    moderation_policy
    notify_of_new_postings_p
    {group_id:integer [db_null]}
}

# -----------------------------------------------------------------------------

page_validation {
    if { [string match {*"*} $topic] } {
	error "Your topic name can't include string quotes.  It makes life too difficult for this collection of software."
    }
}


# no exceptions found

set extra_columns ""
set extra_values ""
set group_report ""

db_transaction {
    set topic_id [db_string next_topic_id "select bboard_topic_id_sequence.nextval from dual"]

    db_dml topic_insert "
    insert into bboard_topics 
    (topic_id,topic,primary_maintainer_id,presentation_type,
     moderation_policy,notify_of_new_postings_p,group_id)
    values
    (:topic_id,:topic,:user_id_from_search,:presentation_type,
     :moderation_policy,:notify_of_new_postings_p,:group_id)"

    # create the administration group for this topic
    ad_administration_group_add "Administration Group for $topic BBoard" "bboard" $topic_id "/bboard/admin-home.tcl?[export_url_vars topic topic_id]"

    # add the current user as an administrator
    ad_administration_group_user_add $user_id_from_search "administrator" "bboard" $topic_id

} on_error {
    # there was an error from the database
    set count [db_string topic_count "
    select count(*) from bboard_topics where topic = :topic"]
    if { $count > 0 } {
	set existing_topic_blather "There is already a discussion group named \"$topic\" in the database.  This is most likely why the database insert failed.  If you think
you are the owner of that group, you can go to its <a
href=\"/bboard/admin-home.tcl?topic=[ns_urlencode $topic]\">admin
page</a>."
    } else {
	set existing_topic_blather ""
    }
    ad_return_error "Topic Not Added" "The database rejected the addition of discussion topic \"$topic\".  Here was
the error message:

<pre>
$errmsg
</pre>

$existing_topic_blather
"
return 0 

}

doc_return  200 text/html "[bboard_header "Topic Added"]

<h2>Topic Added</h2>

There is now a discussion group for \"$topic\" in 
<a href=\"/bboard/index\">[bboard_system_name]</a>

<hr>
Visit the <a href=/bboard/admin-home?topic=[ns_urlencode $topic]>admin page</a>
for $topic.
<p>

$group_report

[bboard_footer]"

