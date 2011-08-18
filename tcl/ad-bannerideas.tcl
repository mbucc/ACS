# $Id: ad-bannerideas.tcl,v 3.0 2000/02/06 03:12:11 ron Exp $
#
# ad-bannerideas.tcl
#
# created by philg@mit.edu on May 15, 1999
# 

util_report_library_entry

proc banner_ideas_gethandle {} {
    return [ns_db gethandle]
}

proc bannerideas_moby_list_internal {} {
    set db [banner_ideas_gethandle]
    set moby_list [database_to_tcl_list_list $db "select idea_id, intro, more_url, picture_html from bannerideas"]
    ns_db releasehandle $db 
    return $moby_list
}

proc bannerideas_moby_list {} {
    return [util_memoize {bannerideas_moby_list_internal} 3600]
}

proc_doc bannerideas_present {idea_id intro more_url picture_html} "Produce an HTML presentation of a banner idea, with appropriate links." {
    # let's treat the picture_html so that it will always align left
    regsub -nocase {align=[^ ]+} $picture_html "" without_align
    regsub -nocase {hspace=[^ ]+} $without_align "" without_hspace
    regsub -nocase {<img} $without_hspace {<img align=left border=0 hspace=8} final_photo_html
    return "<table bgcolor=#EEEEEE width=80% cellspacing=5 cellpadding=5>
<tr>
<td><font size=2 face=\"verdana, arial, helvetica\">
$final_photo_html
$intro
...
<br>
<center>
<a href=\"/bannerideas/more.tcl?[export_url_vars idea_id more_url]\">(more)</a>
</center>
</font>
</td>
</tr>
</table>
"
}

proc_doc bannerideas_random {} "Picks a banner idea at random and returns an HTML presentation of it." {
    set moby_list [bannerideas_moby_list]
    set n_available [llength $moby_list]
    set random_index [randomRange $n_available]
    set random_idea [lindex $moby_list $random_index]
    set idea_id [lindex $random_idea 0]
    set intro [lindex $random_idea 1]
    set more_url [lindex $random_idea 2]
    set picture_html [lindex $random_idea 3]
    return [bannerideas_present $idea_id $intro $more_url $picture_html]
}

util_report_successful_library_load
