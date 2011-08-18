# $Id: ae.tcl,v 3.2.2.3 2000/03/17 08:23:00 mbryzek Exp $
# File: /www/intranet/offices/ae.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
# 
# Adds/edits office information
#

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set_form_variables 0
# group_id (if we're editing)
# return_url (optional)


set db [ns_db gethandle]
if { [exists_and_not_null group_id] } {
    set caller_group_id $group_id
    set selection [ns_db 1row $db \
	    "select g.group_name, g.short_name, o.*
               from im_offices o, user_groups g
              where g.group_id=$caller_group_id
                and g.group_id=o.group_id(+)"]
    set_variables_after_query
    set page_title "Edit office"
    set context_bar [ad_context_bar [list "/" Home] [list "../" "Intranet"] [list index.tcl "Offices"] [list "view.tcl?group_id=$caller_group_id" "One office"] $page_title]

} else {
    set page_title "Add office"
    set context_bar [ad_context_bar [list "/" Home] [list "../" "Intranet"] [list index.tcl "Offices"] $page_title]
    set caller_group_id [database_to_tcl_string $db "select user_group_sequence.nextval from dual"]
 
    # Information about the user creating this office
    set "dp_ug.user_groups.creation_ip_address" [ns_conn peeraddr]
    set "dp_ug.user_groups.creation_user" $user_id

}


set page_body "
<form method=post action=ae-2.tcl>
<input type=hidden name=group_id value=$caller_group_id>
[export_form_vars return_url dp_ug.user_groups.creation_ip_address dp_ug.user_groups.creation_user]

<table border=0 cellpadding=3 cellspacing=0 border=0>

<TR>
<TD ALIGN=RIGHT>Office name:</TD>
<TD><INPUT NAME=group_name SIZE=30 [export_form_value group_name] MAXLENGTH=100></TD>
</TR>

<TR>
<TD ALIGN=RIGHT>Office short name:</TD>
<TD><INPUT NAME=short_name SIZE=30 [export_form_value short_name] MAXLENGTH=100>
  <br><font size=-1>To be used for email aliases/nice urls</font></TD>
</TR>

<TR><TD COLSPAN=2><BR></TD></TR>

<TR>
<TD ALIGN=RIGHT>Phone:</TD>
<TD><INPUT NAME=dp.im_offices.phone.phone [export_form_value phone] SIZE=14 MAXLENGTH=50></TD>
</TR>

<TR>
<TD ALIGN=RIGHT>Fax:</TD>
<TD><INPUT NAME=dp.im_offices.fax.phone [export_form_value fax] SIZE=14 MAXLENGTH=50></TD>
</TR>

<TR><TD COLSPAN=2><BR></TD></TR>

<TR>
<TD VALIGN=TOP ALIGN=RIGHT>Address:</TD>
<TD><INPUT NAME=dp.im_offices.address_line1 [export_form_value address_line1]  SIZE=30 MAXLENGTH=80></TD>
</TR>

<TR>
<TD VALIGN=TOP ALIGN=RIGHT></TD>
<TD><INPUT NAME=dp.im_offices.address_line2 [export_form_value address_line2] SIZE=30 MAXLENGTH=80></TD>
</TR>

<TR>
<TD VALIGN=TOP ALIGN=RIGHT>City:</TD>
<TD><INPUT NAME=dp.im_offices.address_city [export_form_value address_city] SIZE=30 MAXLENGTH=80></TD>
</TR>

<TR>
<TD VALIGN=TOP ALIGN=RIGHT>State:</TD>
<TD>
[state_widget $db [value_if_exists address_state] "dp.im_offices.address_state"]
</TD>
</TR>

<TR>
<TD VALIGN=TOP ALIGN=RIGHT>Zip:</TD>
<TD><INPUT NAME=dp.im_offices.address_postal_code [export_form_value address_postal_code] SIZE=10 MAXLENGTH=80></TD>
</TR>

</TABLE>

<H4>Landlord information</H4>

<BLOCKQUOTE>
<TEXTAREA NAME=dp.im_offices.landlord COLS=60 ROWS=4 WRAP=SOFT>[philg_quote_double_quotes [value_if_exists landlord]]</TEXTAREA>
</BLOCKQUOTE>

<H4>Security information</H4>

<BLOCKQUOTE>
<TEXTAREA NAME=dp.im_offices.security COLS=60 ROWS=4 WRAP=SOFT>[philg_quote_double_quotes [value_if_exists security]]</TEXTAREA>
</BLOCKQUOTE>

<H4>Other information</H4>

<BLOCKQUOTE>
<TEXTAREA NAME=dp.im_offices.note COLS=60 ROWS=4 WRAP=SOFT>[philg_quote_double_quotes [value_if_exists note]]</TEXTAREA>
</BLOCKQUOTE>

<P>

<p><center><input type=submit value=\"$page_title\"></center>
</form>
"

ns_db releasehandle $db

ns_return 200 text/html [ad_partner_return_template]