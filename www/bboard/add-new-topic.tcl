# $Id: add-new-topic.tcl,v 3.0 2000/02/06 03:32:14 ron Exp $
set db [ns_db gethandle]

set user_id [ad_verify_and_get_user_id]

ad_maybe_redirect_for_registration

if {!([bboard_users_can_add_topics_p] || [ad_administrator_p $db])} {
  ad_return_error "You are not allowed to add topics" "Sorry, you are
  not allowed to add discussion group topics on this server."
}

ReturnHeaders

ns_write  "[bboard_header "Add New Topic"]

<h2>Add New Topic</h2>

[ad_context_bar_ws [list "index.tcl" "BBoard"] "Add Topic"]

<hr>

<form action=\"/user-search.tcl\" method=post>
<input type=hidden name=target value=\"/bboard/add-new-topic-2.tcl\">
<input type=hidden name=passthrough value=\"topic presentation_type private_p bboard_group moderation_policy iehelper_notify_of_new_postings_p\">
<input type=hidden name=custom_title value=\"Choose a Member to Add as an Administrator\">

<h3>The Most Important Things</h3>

What do you want to call your forum?  The topic name that you choose
will appear in the alphabetical listing on the [bboard_system_name]
home page.  It will appear on pages visible to users.  It will appear
in URLs.  If you want to let other people link directly to your forum,
they'll need to include this.  So it is probably best to pick some
short and descriptive, e.g., \"darkroom technique\".  The software
adds words like \"Q&A\" and \"forum\" so don't include those in your
topic name.

<P>

New Topic Name:  <input type=text name=topic size=30>

<P>
<h3>Maintainer</h3>
<p>
Search for a user to be primary administrator of this domain by<br>
<table border=0>
<tr><td>Email address:<td><input type=text name=email size=40></tr>
<tr><td colspan=2>or by</tr>
<tr><td>Last name:<td><input type=text name=last_name size=40></tr>
</table>
<p>

<h3>User Group This Topic Is Associated With</h3>
<p>
A topic can be associated with one or more user groups. The topic can be made private
to members of these groups only, or the topic can be made publicly visible and readable.
Select the primary group this topic belongs to below. Other groups can be added later.
<p>
<table><tr><td><select name=bboard_group size=5>
[db_html_select_value_options $db "select group_id, group_name 
from user_groups 
where group_id in
   (select group_id from user_group_map where user_id = $user_id)
 order by group_name"]
</select>
</td><td valign=top>
<input type=checkbox name=private_p value=t checked> Private To Group(s)
</td></tr></table>
<p>


<h3>How this BBoard is presented to users</h3>

You have to choose whether or not this is primarily a Q&A
forum or a threads-based discussion group.  The user interfaces
interoperate, i.e., a posting made a user in the Q&A interface will be
seen in the threads interface and vice versa.  But my software still
needs to know whether this is primarily threads or Q&A.  For example,
if a user signs up for email alerts, this program will send out email
saying \"come back to the forum at http://...\".  The \"come back
URL\" is different for Q&A and threads.

<ul>
<li><input type=radio name=presentation_type value=threads> threads - classical USENET style 
<li><input type=radio name=presentation_type value=q_and_a CHECKED> Q&A - questions and all answers appear on one page, use for discussion groups that tend to have short messages/responses
<li><input type=radio name=presentation_type value=ed_com> Editorial - question and answers appear on separate pages,  answers are collasped by subject line as a default, use for discussion groups that tend to have longer messages/responses 
</ul>

<p>

<br>

(note: I personally greatly prefer the Q&A interface; if people liked
threads, they'd have stuck with USENET.)

<h3>Moderation Type</h3>

What moderation category does this fall under?
<select name=moderation_policy>"
set optionlist [bboard_moderation_policy_order]
ns_write "
[ad_generic_optionlist $optionlist $optionlist]
</select>

<h3>Notification</h3>

If your forum is inactive, you'll probably want this system to send
the primary maintainer email every time someone adds a posting of any kind (new top-level
question or reply).  If you're getting 50 new postings/day then you'll
probably want to disable this feature

<p>

Notify me of all new postings?
<input type=radio name=iehelper_notify_of_new_postings_p value=t CHECKED> Yes <input type=radio name=iehelper_notify_of_new_postings_p value=f> No

<p>
<center>

<input type=submit value=\"Enter This New Topic in the Database\">

</form>

</center>

[ad_admin_footer]
"
