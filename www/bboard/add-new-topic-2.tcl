# /www/bboard/add-new-topic-2.tcl 

ad_page_contract {
    process a new topic form submission
    
    @param topic:trim
    @param user_id_from_search
    @param   presentation_type
    @param   moderation_policy 
    @param   private_p
    @param   notify_of_new_postings_p
    @param   bboard_group
    @author hqm@arsdigita.com
    @creation-date unknown
    @cvs-id add-new-topic-2.tcl,v 3.2.2.6 2000/09/22 01:36:41 kevin Exp
} {
    {topic:trim}
    {user_id_from_search:integer}
    presentation_type
    moderation_policy 
    private_p
    {notify_of_new_postings_p:optional "f"}
    bboard_group
} 

# IE will BASH &not

# set notify_of_new_postings_p $iehelper_notify_of_new_postings_p

if {![bboard_users_can_add_topics_p] && [bboard_check_any_admin_role] == -1} {
	return
}

set exception_text ""
set exception_count 0

if { ![info exists topic] || $topic == "" } {
    append exception_text "<li>You must enter a topic name"
    incr exception_count
}

if { [info exists topic] && [string match {*\"*} $topic] } { 
    append exception_text "<li>Your topic name can't include string quotes.  It makes life too difficult for this collection of software."
    incr exception_count
}

if { $exception_count> 0 } {
    ad_return_complaint $exception_count $exception_text
    return 0
}

# +++ UNFINISHED CODE
#+  We need to figure out how to deal with the new access model - 
# what values do we set for:
# read_access
# write_access
# users_can_initiate_threads_p
#
# these default to reasonable things now, but we need to allow the user to configure them

db_transaction {
    set topic_id [db_string topic_id "select bboard_topic_id_sequence.nextval from dual"]

    db_dml topic_insert "insert into bboard_topics 
                                     (topic_id,
                                      topic,
                                      primary_maintainer_id,
                                      presentation_type,
                                      moderation_policy,
                                      notify_of_new_postings_p)
                          values
                                     (:topic_id,
                                      :topic,
                                      :user_id_from_search,
                                      :presentation_type,
                                      :moderation_policy,
                                      :notify_of_new_postings_p)"

    # create the administration group for this topic
    ad_administration_group_add "Administration Group for $topic BBoard" "bboard" $topic_id "/bboard/admin-home.tcl?[export_url_vars topic topic_id]"

    # add the current user as an administrator
    ad_administration_group_user_add $user_id_from_search "administrator" "bboard" $topic_id

 } on_error {     
     ad_return_error "Topic Not Added" "The database rejected the addition of discussion topic \"$topic\".  Here was
the error message:
<pre>
$errmsg
</pre>
"
 return 0 
}

# the database insert went OK

# release the database handle
db_release_unused_handles 

set page_content "[bboard_header "Topic Added"]

<h2>Topic Added</h2>

There is now a discussion group for \"$topic\" in 
<a href=\"/bboard/index\">[bboard_system_name]</a>

<p>

<hr>
Visit the <a href=\"/bboard/admin-home?[export_url_vars topic topic_id]\">admin page</a>
for $topic.
<p>

[bboard_footer]"

doc_return  200 text/html $page_content











