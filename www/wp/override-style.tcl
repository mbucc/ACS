# /wp/override-style.tcl
ad_page_contract {
    Allows the user to select a style to use to view presentations.
    @creation-date  28 Nov 1999

    @param override_style_id integer- might be -1
    @param overrid_style_temp (is the switch temporary?)

    @author Jon Salz <jsalz@mit.edu>
    @cvs-id override-style.tcl,v 3.1.2.7 2000/08/16 21:49:39 mbryzek Exp
} {
    override_style_id:integer,optional
    override_style_temp:integer,optional
}
# modified 14 Jul 2000 for ACS 3.4 upgrade

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

set whole_page "HTTP/1.0 200 OK
Content-type: text/html
$cookie
"
ns_startcontent -type text/html
append whole_page "<html>
<head><title>Select a Style</title></head>
<body bgcolor=white $on_load>
<form>
<h2>Select a Style</h2><hr>

"

set out "<p><center>When displaying presentations, use the style<br>
<select name=override_style_id>
<option value=\"\"[wp_only_if { $override_style_id == "" } " selected"]>suggested by the author
"

db_foreach wp_sel_style "
    select style_id, name
    from wp_styles
    where public_p = 't'
    or owner is null
    or owner = :user_id
    order by lower(name)
" {
    append out "<option value=$style_id"
    if { $style_id == $override_style_id } {
	append out " selected"
    }
    append out ">$name\n"
}

db_release_unused_handles

append whole_page "$out
</select><input type=submit value=\"Save Preference\">

<p>

<table cellspacing=0 cellpadding=0>
<tr><td><input type=radio name=override_style_temp value=1 [wp_only_if $override_style_temp "checked"]>&nbsp;</td><td>Save my preference only until I close my browser.</td></tr>
<tr><td><input type=radio name=override_style_temp value=0 [wp_only_if { !$override_style_temp } "checked"]>&nbsp;</td><td>Save my preference permanently.</td></tr>
</table>

</center></p>
[wp_footer]
"

ns_write $whole_page
