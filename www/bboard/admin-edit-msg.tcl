# $Id: admin-edit-msg.tcl,v 3.0 2000/02/06 03:32:52 ron Exp $
set_form_variables

# msg_id is the key

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}


set selection [ns_db 1row $db "select bboard.*, users.email, users.first_names || ' ' || users.last_name as name, bboard_topics.topic
from bboard, users, bboard_topics
where users.user_id = bboard.user_id
and bboard_topics.topic_id = bboard.topic_id
and msg_id = '$msg_id'"]
set_variables_after_query

set QQtopic [DoubleApos $topic]
 
if  {[bboard_get_topic_info] == -1} {
    return}

if {[bboard_admin_authorization] == -1} {
	return}

# find out if this is usgeospatial
set presentation_type [database_to_tcl_string $db "select presentation_type from bboard_topics where topic_id=$topic_id"]

ReturnHeaders
ns_write "<html>
<head>
<title>Edit \"$one_line\"</title>
</head>
<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>

<h3>Edit \"$one_line\"</h3>

(<a href=\"admin-home.tcl?[export_url_vars topic topic_id]\">main admin page</a>)
<hr>

<form method=post action=admin-edit-msg-2.tcl>
<input type=hidden name=msg_id value=\"$msg_id\">

<table>

<tr><th>Subject Line<br><td><input type=text name=one_line size=50 value=\"[philg_quote_double_quotes $one_line]\"></tr>

<tr><th>Poster Email Address:<td> $email</tr>

<tr><th>Poster Full Name:<td> $name</tr>
"

if {$presentation_type == "usgeospatial"} {
    ns_write "<input type=hidden name=usgeospatial_p value=\"t\">
<tr><th>EPA Region<td><input name=epa_region value=\"$epa_region\"></tr>
<tr><th>USPS<td><input name=usps_abbrev value=\"$usps_abbrev\"></tr>
<tr><th>FIPS<td><input name=fips_county_code value=\"$fips_county_code\"></tr>
<tr><th>TRI ID<td><input name=tri_id value=\"$tri_id\"></tr>
"
}

# we have to quote this in case it contains a TEXTAREA itself
ns_write "<tr><th>Message<td><textarea name=message rows=5 cols=70>[philg_quote_double_quotes $message]</textarea>

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
