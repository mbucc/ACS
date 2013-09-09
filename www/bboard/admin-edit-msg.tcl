# /www/bboard/admin-edit-msg.tcl
ad_page_contract {
    Form for the admin to modify a message

    @cvs-id admin-edit-msg.tcl,v 3.1.6.4 2000/09/22 01:36:44 kevin Exp
} {
    msg_id:notnull
}

# -----------------------------------------------------------------------------

db_1row msg_info "
select bboard.one_line,
       bboard.message,
       bboard.html_p,
       bboard.epa_region,
       bboard.usps_abbrev,
       bboard.fips_county_code,
       users.email, 
       users.first_names || ' ' || users.last_name as name, 
       bboard_topics.topic
from   bboard, 
       users, 
       bboard_topics
where  users.user_id = bboard.user_id
and    bboard_topics.topic_id = bboard.topic_id
and    msg_id = :msg_id"

 
if  {[bboard_get_topic_info] == -1} {
    return
}

if {[bboard_admin_authorization] == -1} {
    return
}

# find out if this is usgeospatial
db_1row presentation_type "
select presentation_type from bboard_topics where topic_id = :topic_id"


append page_content "
[bboard_header "Edit \"$one_line\""]

<h3>Edit \"$one_line\"</h3>

(<a href=\"admin-home?[export_url_vars topic topic_id]\">main admin page</a>)
<hr>

<form method=post action=admin-edit-msg-2>
<input type=hidden name=msg_id value=\"$msg_id\">

<table>

<tr><th>Subject Line<br><td><input type=text name=one_line size=50 value=\"[philg_quote_double_quotes $one_line]\"></tr>

<tr><th>Poster Email Address:<td> $email</tr>

<tr><th>Poster Full Name:<td> $name</tr>
"

if {$presentation_type == "usgeospatial"} {
    append page_content "<input type=hidden name=usgeospatial_p value=\"t\">
<tr><th>EPA Region<td><input name=epa_region value=\"$epa_region\"></tr>
<tr><th>USPS<td><input name=usps_abbrev value=\"$usps_abbrev\"></tr>
<tr><th>FIPS<td><input name=fips_county_code value=\"$fips_county_code\"></tr>
"
}

# we have to quote this in case it contains a TEXTAREA itself

# If message has a textarea in it, we probably screwed up screening HTML

append page_content "<tr><th>Message<td><textarea name=message rows=5 cols=70>[philg_quote_double_quotes $message]</textarea>

</tr>
<tr><th align=left>Text above is:
<td><select name=html_p>
 [ad_generic_optionlist {"Plain Text" "HTML"} {"f" "t"} $html_p]
</select></td>
</tr>
</table>




<P>

<center>


<input type=submit value=Submit>

</center>

</form>

[bboard_footer]"

doc_return  200 text/html $page_content
