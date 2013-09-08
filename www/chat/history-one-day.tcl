# /chat/history-one-day.tcl

ad_page_contract {

    Display messages post in the chat room on the given date.

    @author Aurelius Prochazka (aure@arsdigita.com)
    @author Philip Greenspun (philg@mit.edu)
    @author Sarah Ahmed (ahmeds@arsdigita.com)
    @param chat_room_id 
    @param the_date date that messages are post
    @param scope
    @param owner_id
    @param group_id
    @param group_vars_set
    @param on_which_group_id
    @param on_what_id
    @creation-date 1999-11-18
    @cvs-id: history-one-day.tcl,v 3.3.2.6 2000/09/22 01:37:08 kevin Exp
} {
    chat_room_id:naturalnum,notnull
    the_date:notnull
    scope:optional
    owner_id:naturalnum,optional
    group_id:naturalnum,optional
    group_vars_set:optional
    on_which_group_id:naturalnum,optional
    on_what_id:naturalnum,optional
}

ad_scope_error_check

set user_id [ad_scope_authorize $scope registered group_member none]

set private_group_id [chat_room_group_id $chat_room_id]

if { ![empty_string_p $private_group_id] && 
     ![ad_user_group_member_cache $private_group_id $user_id]} {
    ad_returnredirect "bounced-from-private-room?[export_url_scope_vars chat_room_id]"
    return
}

set pretty_name [db_string chat_history_one_day_get_pretty_name {
    select pretty_name
    from   chat_rooms
    where  chat_room_id = :chat_room_id} -default "" ]

if [empty_string_p $pretty_name] {
    ad_scope_return_error "Room deleted" "We couldn't find the chat room you tried to enter. It was probably deleted by the site administrator."
    return
}

set items [list]

db_foreach chat_history_one_day_find_all_chat_query {
    select to_char(creation_date, 'HH24:MI:SS') as time, 
           nvl(msg_bowdlerized, msg) as filtered_msg, 
           first_names, 
           last_name, 
           creation_user
    from   chat_msgs, users
    where  chat_msgs.creation_user = users.user_id
    and    chat_room_id = :chat_room_id
    and    chat_msgs.approved_p = 't'
    and    trunc(creation_date) = :the_date
    and    system_note_p <> 't'
    order by creation_date
} { 
    set filtered_msg [ns_quotehtml $filtered_msg]
    append items "<a target=newwindow href=\"/shared/community-member?[export_url_scope_vars]&user_id=$creation_user\">$first_names $last_name</a> ($time) $filtered_msg<br>\n"
}

set page_content "

[ad_scope_header "[util_AnsiDatetoPrettyDate $the_date]: $pretty_name"]
[ad_scope_page_title [util_AnsiDatetoPrettyDate $the_date]]

[ad_scope_context_bar_ws_or_index [list "index?[export_url_scope_vars]" [chat_system_name]] [list "chat?[export_url_scope_vars chat_room_id]" "One Room"]  [list "history?[export_url_scope_vars chat_room_id]" "History"] "One Day"]

<hr>

$pretty_name on [util_AnsiDatetoPrettyDate $the_date]:

<ul>

$items

</ul>

[ad_scope_footer]
"

#release unused handles

doc_return  200 text/html $page_content

