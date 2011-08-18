#
# /www/education/class/admin/new-bboard-topic-add.tcl
# aileen@mit.edu, randyg@mit.edu
# feb, 2000
# based on add-new-topic.tcl,v 1.3.4.1 2000/02/03 09:19:03 ron Exp
#

set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Manage Communications"]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]


set return_string "

[ad_header "Add New Topic"]

<h2>Add New Topic</h2>
[ad_context_bar_ws_or_index [list "../one.tcl" "$class_name Home"] [list "" "Administration"] "Add a new topic"]

<hr>

<form action=\"/admin/users/search.tcl\" method=get>
<input type=hidden name=target value=\"[edu_url]class/admin/new-bboard-topic-add-2.tcl\">
<input type=hidden name=passthrough value=\"topic presentation_type moderation_policy iehelper_notify_of_new_postings_p role group_id\">
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
<h3>Group and Role-based Access Control</h3>
<p>
Select the group that this bboard is used for and set the access level for this bboard.
<p><table>
<tr><td>Group:</td><td>
<select name=group_id>
<option value=$class_id>$class_name
"

set selection [ns_db select $db "select team_id, team_name from edu_teams where class_id=$class_id"]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query

    append return_string "
    <option value=$team_id>$team_name
    "
}

append return_string "
</select>
</tr><tr>
<td>Role:</td>
<td><select name=role>
<option value=\"\">Public
"

set role_list [edu_get_roles_for_group $db $class_id]

foreach role $role_list {
    append return_string "<option value=[lindex $role 0]>[lindex $role 1]"
}

append return_string "
</select>
</tr></table>

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

append return_string "
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

[ad_footer]
"


ns_db releasehandle $db

ns_return 200 text/html $return_string
