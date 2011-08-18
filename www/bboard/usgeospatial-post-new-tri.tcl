# $Id: usgeospatial-post-new-tri.tcl,v 3.0.4.1 2000/04/28 15:09:44 carsten Exp $
set_the_usual_form_variables

# tri_id, topic, force_p (option)

# unless force_p exists and is true, let's first figure out if there
# are any existing discussions about this facility, if so, we redirect
# them out to a county page if not, they just stat a new thread here

set db [ns_db gethandle]

if { ![info exists force_p] || $force_p == 0 } {
    set n_existing [database_to_tcl_string $db "select count(*) from bboard where topic_id = $topic_id and tri_id = '$QQtri_id'"]

    if { $n_existing > 0 } {
	ad_returnredirect "usgeospatial-one-facility.tcl?[export_url_vars topic tri_id]"
	return
    }
}


if {[bboard_get_topic_info] == -1} {
    return
}


#check for the user cookie

set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
   ad_returnredirect /register.tcl?return_url=[ns_urlencode "[bboard_partial_url_stub]usgeospatial-post-new-tri.tcl?[export_url_vars topic tri_id]"]
    return
}

set menubar_items [list]
lappend menubar_items "<a href=\"usgeospatial-search-form.tcl?[export_url_vars topic topic_id]\">Search</a>"

lappend menubar_items "<a href=\"help.tcl?[export_url_vars topic topic_id]\">Help</a>"

lappend menubar_items "<a href=\"sample-questions.tcl?[export_url_vars topic topic_id]\">Sample Questions</a>"

set top_menubar [join $menubar_items " | "]

set selection [ns_db 0or1row $db "select rsf.*, epa.epa_region
from Rel_Search_Fac rsf, bboard_epa_regions epa
where tri_id = '$QQtri_id'
and rsf.st = epa.usps_abbrev"]

set_variables_after_query

ReturnHeaders 

ns_write "[bboard_header $facility]

<h2>Post a New Message</h2>

about <a href=\"/env-releases/facility.tcl?tri_id=[ns_urlencode $tri_id]\">$facility</a> into <a href=\"usgeospatial-2.tcl?[export_url_vars topic epa_region]\">the $topic (Region $epa_region) forum</a>.

<hr>

\[$top_menubar\]

<br>
<br>

<form method=post action=\"insert-msg.tcl\" target=\"_top\">
[export_form_vars topic tri_id]

[philg_hidden_input usgeospatial_p t]
[philg_hidden_input refers_to NEW]

<table cellspacing=6>

<tr><th>Subject Line<td><input type=text name=one_line size=50></tr>

<tr><th>Notify Me of Responses
<td><input type=radio name=notify value=t CHECKED> Yes
<input type=radio name=notify value=f> No

<tr><th>Message<td>&nbsp;</tr>

</table>

<blockquote>

<textarea name=message rows=10 cols=70 wrap=hard></textarea>

</blockquote>

<P>

<center>


<input type=submit value=Post>

</center>

</form>


[bboard_footer]"
