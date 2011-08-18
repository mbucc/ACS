# $Id: override-style.tcl,v 3.0 2000/02/06 03:55:06 ron Exp $
# File:        index.tcl
# Date:        28 Nov 1999
# Author:      Jon Salz <jsalz@mit.edu>
# Description: Allows the user to select a style to use to view presentations.
# Inputs:      override_style_id
#              override_style_temp (is the switch temporary?)

set_the_usual_form_variables 0

if { [info exists override_style_id] && [regexp {^-?[0-9]*$} $override_style_id] } {
    set override_style_temp [expr { [info exists override_style_temp] && $override_style_temp == 1 }]
    set cookie "Set-Cookie: wp_override_style=$override_style_id,$override_style_temp; Path=/"
    if { !$override_style_temp } {
	append cookie "; Expires=Fri, 01-Jan-2010 01:00:00 GMT"
    }
    append cookie "\n"
    set on_load "onLoad=\"opener.location.reload()\""
} else {
    if { ![regexp {wp_override_style=(-?[0-9]*),([01])} [ns_set get [ns_conn headers] Cookie] all override_style_id override_style_temp] } {
	set override_style_id ""
	set override_style_temp 1
    }
    set cookie ""
    set on_load ""
}

set user_id [ad_verify_and_get_user_id]


ns_write "HTTP/1.0 200 OK
Content-type: text/html
$cookie
<html>
<head><title>Select a Style</title></head>
<body bgcolor=white $on_load>
<form>
<h2>Select a Style</h2><hr>

"

set db [ns_db gethandle]

set out "<p><center>When displaying presentations, use the style<br>
<select name=override_style_id>
<option value=\"\"[wp_only_if { $override_style_id == "" } " selected"]>suggested by the author
"

wp_select $db "
    select style_id, name
    from wp_styles
    where public_p = 't'
    or owner is null
    or owner = $user_id
    order by lower(name)
" {
    append out "<option value=$style_id"
    if { $style_id == $override_style_id } {
	append out " selected"
    }
    append out ">$name\n"
}

ns_write "$out
</select><input type=submit value=\"Save Preference\">

<p>

<table cellspacing=0 cellpadding=0>
<tr><td><input type=radio name=override_style_temp value=1 [wp_only_if $override_style_temp "checked"]>&nbsp;</td><td>Save my preference only until I close my browser.</td></tr>
<tr><td><input type=radio name=override_style_temp value=0 [wp_only_if { !$override_style_temp } "checked"]>&nbsp;</td><td>Save my preference permanently.</td></tr>
</table>

</center></p>
[wp_footer]
"
