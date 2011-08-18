# $Id: bboard-ae.tcl,v 3.1.4.2 2000/03/17 08:56:32 mbryzek Exp $
#
# File: /www/intranet/customers/bboard-ae.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Once bboard is scoped, this page will allow us to easily link 
# customers with their own bboards


set_form_variables 0

# group_id
# topic_id if we're editing

set user_id [ad_get_user_id]

set db [ns_db gethandle]

if { [exists_and_not_null topic_id] } {
    set selection [ns_db 1row $db \
	    "select * from bboard_topics where topic_id=$topic_id"]
    set_variables_after_query
    set page_title "Edit BBoard Topic"
} else {
    set selection [ns_db 1row $db \
	    "select * from user_groups where group_id=$group_id"]
    set_variables_after_query
    set topic $group_name
    set page_title "Add BBoard Topic"
}

set context_bar [ad_context_bar [list "/" Home] [list ../index.tcl "Intranet"] [list index.tcl "Customers"] [list "view.tcl?[export_url_vars group_id]" "One customer"] [list "staff-server.tcl?[export_url_vars group_id]" "Staff server"] $page_title]

set page_body "
[ad_partner_header]
<form action=\"/user-search.tcl\" method=get>
[export_form_vars group_id]
<input type=hidden name=target value=\"[im_url_stub]/customers/bboard-ae-2.tcl\">
<input type=hidden name=passthrough value=\"topic group_id presentation_type moderation_policy iehelper_notify_of_new_postings_p\">
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

New Topic Name:  <input type=text name=topic [export_form_value topic] size=30>

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

append page_body "
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

ns_db releasehandle $db

ns_return 200 text/html $page_body