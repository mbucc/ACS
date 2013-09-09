# /bboard/admin-home.tcl 

ad_page_contract {
    @author philg@mit.edu
    @creation-date 1995
    @cvs-id admin-home.tcl,v 3.4.2.7 2000/11/17 07:03:33 kevin Exp
} {
    topic
    topic_id:integer,optional
}

# a bboard administrator's page where that person can participate
# in the discussion (most common usage), moderate out inappropriate
# messages (common usage), change the bboard's properties (uncommon usage
# that should be given much less prominence)


if {[bboard_get_topic_info] == -1} {
    return
}

if {[bboard_admin_authorization] == -1} {
    return
}

# cookie checks out; user is authorized

if { ![db_0or1row topic_data_get "
select bt.*,
       u.email as maintainer_email, 
       u.first_names || ' ' || u.last_name as maintainer_name
from   bboard_topics bt, users u
where  bt.topic_id = :topic_id
and    bt.primary_maintainer_id = u.user_id" -column_set selection] } {
    [bboard_return_cannot_find_topic_page]
    return
}
# we found the data we needed

set threads_checked ""
set q_and_a_checked ""
set ed_com_checked ""
switch $presentation_type {
    threads { set threads_checked " CHECKED" }
    q_and_a { set q_and_a_checked " CHECKED" }
    ed_com  { set ed_com_checked " CHECKED" }
}

#    set usgeospatial_checked ""
#    usgeospatial { set usgeospatial_checked " CHECKED" }


append doc_body "<html>
<head>
<title>BBoard Admin for $topic</title>
</head>
<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>

<h2>Administration for \"$topic\"</h2>

[ad_context_bar_ws_or_index [list "index.tcl" [bboard_system_name]] [list [bboard_raw_backlink $topic_id $topic $presentation_type 0] $topic] "Administer"]

<hr>

<h3>Daily Tasks</h3>

<ul>
<li>visit the user-visible page:  <a href=\"main-frame?[export_url_vars topic topic_id]\">threads</a> | 
<a href=\"q-and-a?[export_url_vars topic topic_id]\">Q&amp;A/Editorial</a> |

<li>visit the administration page:  
<a href=\"admin-delete-and-view-threads?[export_url_vars topic topic_id]\">threads</a> |
<a href=\"admin-q-and-a?[export_url_vars topic topic_id]\">Q&amp;A/Editorial</a> |

<li><a href=\"admin-expired-threads?[export_url_vars topic topic_id]\">look at expired threads</a> (a Q&A only thing)

</ul> 

<h3>Community</h3>

This software can help you view, spam, count, or randomly select (for
contests) the people who participate in your forum.

<p>

Pick out the readers who've posted at least

<form method=post action=admin-community-view>
[export_form_vars topic topic_id]
<input type=text name=n_postings value=1 size=4> times

between

[_ns_dateentrywidget start_date]

and

[_ns_dateentrywidget end_date]

<P>
<center>
<input type=submit value=\"view the readers\">
</center>
</form>

<h3>Bozo Filters</h3>

You can instruct this system to automatically reject postings that
match certain patterns.  For example, at photo.net we want to refuse
postings that contain the string \"aperature\".  Invariably, people
who can't spell \"aperture\" turn out to be idiots.

"

set sql "select * 
         from bboard_bozo_patterns 
         where topic_id = :topic_id
         order by upper(the_regexp)"

set bozo_items ""
db_foreach items_list $sql {
    append bozo_items "<li><a href=\"admin-bozo-pattern?[export_url_vars topic topic_id the_regexp]\">$the_regexp</a>\n"
}

if [empty_string_p $bozo_items] {
    set bozo_items "there aren't any bozo patterns associated with this forum right now"
}

append doc_body "<ul>
$bozo_items
<p>
<li><a href=\"admin-bozo-pattern-add?[export_url_vars topic topic_id]\">add pattern</a>
</ul>

<h3>How this BBoard is presented to users</h3>

Remember that although this bboard runs from a purpose-built DB-backed
Web server, it is designed to look like it is part of the original
static Web service.  The pages will be displayed with your email
address at the bottom, and a link back to your static server.  (If you
want more customization, you'll just have to read <a
href=\"http://photo.net/wtr/dead-trees/\">Philip Greenspun's
book on Web service design</a>).

<form method=post action=\"admin-update-topics-table\">
[export_form_vars topic topic_id]

<p>

The most important thing is the backlink URL, i.e., the URL for
<em>your</em> server.  This will be offered by my server as a link
back to you.  Make sure you have the full \"http://\"  in front, e.g.,
\"http://gardenhosestoday.com\".

<p>

Backlink:  <input type=text name=backlink size=30 value=\"$backlink\"> 

<P>

You probably don't want the Q&A forum page saying \"this is associated
with http://complicated-domain.com/bunch-of-dirs/foobar.html\".  So
put in a title for the above URL,  e.g., \"Garden Hose Magazine\".

<p>

Backlink Title:  <input type=text name=backlink_title size=30 value=\"$backlink_title\"> 

<p>

Primary Maintainer: [db_string name_get "
select first_names || ' ' || last_name || ' ' || '(' || email || ')'
from users where user_id = :primary_maintainer_id"]

(<a href=\"admin-update-primary-maintainer?[export_url_vars topic topic_id]\">update</a>)

<br>
(note:  messages from the above email address will be displayed first in a Q&A forum thread, even if the maintainer was not the first person to answer)

<P>

<h3>Presentation Type</H3>

You have to choose whether or not this is primarily a Q&A
forum, a threads-based discussion group, or an editorial stlye.  
The user interfaces interoperate, i.e., a posting made a user in 
the Q&A interface will be seen in the threads interface and vice versa.  
But my software still needs to know whether this is primarily threads, Q&A
or editorial.  For example,
if a user signs up for email alerts, this program will send out email
saying \"come back to the forum at http://...\".  The \"come back
URL\" is different for Q&A and threads.

<ul>
<li><input type=radio name=presentation_type value=threads$threads_checked> threads - classical USENET style 
<li><input type=radio name=presentation_type value=q_and_a$q_and_a_checked> Q&A - questions and all answers appear on one page, use for discussion groups that tend to have short messages/responses
<li><input type=radio name=presentation_type value=ed_com$ed_com_checked> Editorial - question and answers appear on separate pages,  answers are collasped by subject line as a default, use for discussion groups that tend to have longer messages/responses 
</ul>

<p>

<br>

(note: I personally greatly prefer the Q&A interface; if people liked
threads, they'd have stuck with USENET.)

<h3>How Threads are Presented</h3>

Whenever postings are displayed in a \"one line summary\" form, you
can choose to have this server add email address, name, and/or posting
date to each line in the summary.  

<P>

Subject Line Suffix: <input type=text name=subject_line_suffix size=15 value=\"$subject_line_suffix\">
<br>
(legal values are blank, \"name\", \"email\", \"date\", separated by spaces)

<p>

Q&A threads are presented as a list.  You can choose either <p>
"

#<a href=\"usgeospatial?[export_url_vars topic topic_id]\">US Geospatial</a>
#<a href=\"admin-usgeospatial?[export_url_vars topic topic_id]\">US Geospatial</a> 

#<li><input type=radio name=presentation_type value=usgeospatial$usgeospatial_checked> US Geospatial

if { $q_and_a_sort_order == "asc" } {
    append doc_body "<input type=radio name=q_and_a_sort_order value=asc CHECKED> Oldest on top
<input type=radio name=q_and_a_sort_order value=desc> Newest on top
"} else {
    append doc_body "<input type=radio name=q_and_a_sort_order value=asc> Oldest on top
<input type=radio name=q_and_a_sort_order value=desc CHECKED> Newest on top
"
}

append doc_body "

<h3>Categorization</h3>

After a Q&A forum has collected a few thousand messages, it becomes
tough for users to find archived threads, even when the software is
running on a server with a full-text search engine.  Categorization
lets you support browsing as well as searching.  As the administrator,
you are always able to recategorize messages and define new
categories.  If you want less work and don't mind a little chaos, then
you can allow users to categorize their own questions (they get a
select menu when they post a new question).  If you don't mind a lot
of chaos, you can allow users to define new categories.

<p>

"

set raw_form_vars "Present Categorized?
<input type=radio name=q_and_a_categorized_p value=t CHECKED> Yes
<input type=radio name=q_and_a_categorized_p value=f> No

<P>

Ask User to Categorize?
<input type=radio name=q_and_a_solicit_category_p value=t CHECKED> Yes
<input type=radio name=q_and_a_solicit_category_p value=f> No

<p>

Allow Users to Add New Categories?
<input type=radio name=q_and_a_cats_user_extensible_p value=t> Yes
<input type=radio name=q_and_a_cats_user_extensible_p value=f CHECKED> No

<p>

Remember that new questions will always be presented on top for
however many days you specify, even if they are categorized.  After
the \"days considered new\" period has lapsed, a question will show up
underneath a category heading.

<p>

Days Considered New:  <input type=text name=q_and_a_new_days size=5 value=\"$q_and_a_new_days\"> 

<P>

If your forum becomes extremely popular, you might want to trim down
the top-level page so that it shows only the subject lines for new
messages.  For older messages, all you see are the category names and
a count of how many messages are in that category.

<p>

Show only the categories (and a count) on the top level page?
<input type=radio name=q_and_a_show_cats_only_p value=t> Yes
<input type=radio name=q_and_a_show_cats_only_p value=f CHECKED> No
"

# way back when, we saved this ns_set so we could perform the following
# magic
set merged_form [bt_mergepiece $raw_form_vars $selection]

append doc_body "$merged_form

<p>

Note: all the categorization stuff is ignored in the threads (frames)
interface.

<p>

Once you've set up categorization, you can add categories in the Q&A
admin pages (while looking at threads), or you can take an overall
look in the <a href=\"admin-edit-categories?[export_url_vars topic topic_id]\">edit categories page</a>.

<h3>Interest Level</h3>

After a Q&A forum has collected a few <em>tens of thousands</em> of
messages, it becomes tough for users to find interesting threads, even
when you have categorization turned on.  For example, in my photo.net
forum someone asked what the \"QC\" meant in a Nikon 135 QC lens,
which was manufactured in the early 1970s.  I don't want to delete it,
because someone three years from now might search for \"Nikon QC\" and
find it useful.  But I don't want it cluttering up my Nikon category
where the majority of readers are using modern equipment.  So I
enabled my interest level system.  As the administrator, you can rate
things on a scale from 0 to 10.  Anything 3 or below is deemed
\"uninteresting\" and separated from the other threads in a category.
In the long run, I'll probably add an option for users to see the
threads that the administrator has specifically marked interesting (8
or higher?).  Remember that you don't have to mark each thread.
Threads without a number are still considered \"interesting\".

<p>

Use Interest Level System?
"

if { $q_and_a_use_interest_level_p == "t" } {
    append doc_body "<input type=radio name=q_and_a_use_interest_level_p value=t CHECKED> Yes
<input type=radio name=q_and_a_use_interest_level_p value=f> No" } else {
    append doc_body "<input type=radio name=q_and_a_use_interest_level_p value=t> Yes
    <input type=radio name=q_and_a_use_interest_level_p value=f CHECKED> No" 
}

append doc_body "

<h3>Policy</h3>

If you choose, you can explain to users what this forum is supposed to
be for.  An \"About\" link will be added to the top level page.  For
example, if you're using this software for tech support, you could say
\"You can expect a response within 24 hours from one of the following
people:\".  If you're running a contest (see below) then you could use
this message to explain how frequently winners are chosen and what are
the possible prizes.

<p>

<textarea name=policy_statement rows=5 cols=70>
$policy_statement
</textarea>

<h3>Discouraging Users from Posting</h3>

Sometimes you can have too much of a good thing.  When your site is
young, you'll be eager for all kinds of posts (at least I was).  But
after 100,000 messages, you'll get sick of repeats.  So you can put in
a little canned message encouraging users to check your site's static
content and/or a search engine before posting a question.  Note that
if this system is running on a machine with a full-text search engine
installed as part of the RDBMS then a \"search the forum\" link is
offered by default to everyone.

<p>

<textarea name=pre_post_caveat rows=5 cols=70>
$pre_post_caveat
</textarea>

<h3>Notification</h3>

If your forum is inactive, you'll probably want this system to send
you email every time someone adds a posting of any kind (new top-level
question or reply).  If you're getting 50 new postings/day then you'll
probably want to disable this feature

<p>

Notify me of all new postings?

"

if { $notify_of_new_postings_p == "t" } {
    append doc_body "<input type=radio name=notify_of_new_postings_p value=t CHECKED> Yes <input type=radio name=notify_of_new_postings_p value=f> No "
} else {
    append doc_body "<input type=radio name=notify_of_new_postings_p value=t> Yes <input type=radio name=notify_of_new_postings_p value=f CHECKED> No "
}

append doc_body "<P>

Note that users can use the alerts feature to get instant notification
of all postings themselves.  The From: header in this case is set to
that of the person who contributed the new posting.  If users who've
added alerts lose their email account, then this can generate a lot of
bounced email.  In this case, as the administrator, you'll want to <a
href=\"admin-view-alerts.tcl?[export_url_vars topic topic_id]\">view all
the alerts</a> and disable the ones you think are causing bounces.

<p>
<center>

<input type=submit value=\"Update this Information in the Database\">

</center>

</form>

<h3>Things that you can't do (well, not from here)</h3>

<ul>

<li>you cannot change the topic name because it is used as a database
key in the bboard messages table.

<li>you can't delete a topic.  That's too great a security risk.  You have to 
<a href=\"mailto:[bboard_system_owner]\">send email to [bboard_system_owner]</a> 
if you want to kill a topic.

</ul>

<h3>Weird stuff</h3>

This is a section of parameters for people who are using my software
in unintended ways (i.e., not really as a forum at all).  For example,
someone wanted to put up a service with a fixed set of threads, e.g.,
one for each U.S. state.  Users would be free to add any message they
wanted underneath any of the threads set up by the administrator (oh
yes, this works by removing the 
<a href=\"q-and-a-post-new?[export_url_vars topic topic_id]\">Ask a Question</a>
link from the top level page).

<p>

<form method=post action=\"admin-update-topics-table\">
[export_form_vars topic topic_id]

Allow Users to initiate threads?

"

if { $users_can_initiate_threads_p == "f" } {
    append doc_body "<input type=radio name=users_can_initiate_threads_p value=t> Yes
<input type=radio name=users_can_initiate_threads_p value=f CHECKED> No" 
} else {
    append doc_body "<input type=radio name=users_can_initiate_threads_p value=t CHECKED> Yes
<input type=radio name=users_can_initiate_threads_p value=f> No" } 

append doc_body "
<p>
<center>

<input type=submit value=\"Update Weird Stuff Parameters in the Database\">

</center>

</form>

"

if [ad_parameter FileUploadingEnabledP bboard 0] {
    append doc_body "
<h3>File/Image Uploading</h3>

The server is configured to permit user uploads of images and other
files.  Essentially a user can attach an arbitrary file to a message
or, in the case of an image, have it displayed in-line with the message.

<form method=GET action=\"admin-update-uploads-anticipated\">
[export_form_vars topic topic_id]

Types of files you anticipate:
<select name=uploads_anticipated>
[html_select_value_options [list [list "" "Disabled"] [list images "Images"] [list files "Files"] [list images_or_files "Images or Files"]] $uploads_anticipated]
</select>
<br>
<br>
<center>
<input type=submit value=\"Update Image Uploading Parameter\">
</center>
</form>
"
}

append doc_body "

[bboard_footer]
"


doc_return  200 text/html $doc_body
