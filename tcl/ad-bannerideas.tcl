# /tcl/ad-bannerideas.tcl

ad_library {

    Some procedures for the bannerideas module.
    
    @author philg@mit.edu
    @date May 15, 1999
    @cvs-id ad-bannerideas.tcl,v 3.1.6.3 2000/09/14 07:36:27 ron Exp
}

ad_proc -private -deprecated -warn banner_ideas_gethandle {} {

    We shouldn't be using handles anymore.
} {
    return [ns_db gethandle]
}

ad_proc -private bannerideas_moby_list_internal {} {

    Return all the banner ideas in a tcl data structure
} {
    set moby_list [db_list_of_lists banner_idea_list_query "select idea_id, intro, more_url, picture_html from bannerideas"]
    db_release_unused_handles 
    return $moby_list
}

ad_proc -private bannerideas_moby_list {} {

    Caches bannerideas_moby_list_internal for one hour
} {
    return [util_memoize {bannerideas_moby_list_internal} 3600]
}

ad_proc -public bannerideas_present {idea_id intro more_url picture_html} {

    Produce an HTML presentation of a banner idea, with appropriate
    links. Treats the picture html so it aligns left, stripping align and
    hspace tags.
} {
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
<a href=\"/bannerideas/more?[export_url_vars idea_id more_url]\">(more)</a>
</center>
</font>
</td>
</tr>
</table>
"
}

ad_proc -public bannerideas_random {} {

    Picks a banner idea at random and returns an HTML presentation of it.
} {
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
