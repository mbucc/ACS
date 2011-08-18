# /www/education/class/admin/add-new-bboard-topic-2.tcl
# aileen@mit.edu, randyg@mit.edu
# feb, 2000
# based on add-new-topic-2.tcl,v 1.6.4.1 2000/02/03 09:19:01 ron Exp
set_the_usual_form_variables

# IE will BASH &not

set notify_of_new_postings_p $iehelper_notify_of_new_postings_p
set QQnotify_of_new_postings_p $QQiehelper_notify_of_new_postings_p


set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Manage Communications"]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]

set exception_text ""
set exception_count 0

if { ![info exists topic] || $topic == "" } {
    append exception_text "<li>You must enter a topic name"
    incr exception_count
}

if { [info exists topic] && [string match {*"*} $topic] } {
    append exception_text "<li>Your topic name can't include string quotes.  It makes life too difficult for this collection of software."
    incr exception_count
}


if { $exception_count> 0 } {
    ad_return_complaint $exception_count $exception_text
    return 0
}

# no exceptions found

set extra_columns ""
set extra_values ""
set group_report ""

with_transaction $db {
    set topic_id [database_to_tcl_string $db "select bboard_topic_id_sequence.nextval from dual"]
    ns_db dml $db "insert into bboard_topics (topic_id,topic,primary_maintainer_id,presentation_type,moderation_policy,notify_of_new_postings_p, role, group_id)
values
 ($topic_id,'$QQtopic',$user_id_from_search,'$QQpresentation_type','$QQmoderation_policy','$QQnotify_of_new_postings_p', '$QQrole', $group_id)"

    # create the administration group for this topic
    ad_administration_group_add $db "Administration Group for $topic BBoard" "bboard" $topic_id "/bboard/admin-home.tcl?[export_url_vars topic topic_id]"

    # add the current user as an administrator
    ad_administration_group_user_add $db $user_id_from_search "administrator" "bboard" $topic_id

} {
    # there was an error from the database
    set count [database_to_tcl_string $db "select count(*) from bboard_topics where topic = '$QQtopic'"]
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


ns_return 200 text/html "[bboard_header "Topic Added"]

<h2>Topic Added</h2>

There is now a discussion group for \"$topic\" in 
<a href=\"/bboard/\">[bboard_system_name]</a>

<hr>
Visit the <a href=/bboard/admin-home.tcl?topic=[ns_urlencode $topic]>admin page</a>
for $topic.
<p>

$group_report

[bboard_footer]"

