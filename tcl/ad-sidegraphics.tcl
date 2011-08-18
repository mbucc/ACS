# $Id: ad-sidegraphics.tcl,v 3.0 2000/02/06 03:12:46 ron Exp $
# 
# ad-sidegraphics.tcl
#
# created April 21, 1999 by philg@mit.edu
#

proc_doc ad_image_size {graphics_url} "Returns Tcl list of WIDTH and HEIGHT of image, works for both JPEG and GIF.  We need our own proc because AOLserver is stupid and has separate API calls for JPEG and GIF." {
    # call ns_gifsize or ns_jpegsize, as appropriate
    if [string match "http://*" [string tolower $graphics_url]] {
	# this is a image on a foreign server, we won't be able to 
	# figure out its size 
	return ""
    }
    set what_aolserver_told_us ""
    set full_filename "[ns_info pageroot]$graphics_url"
    set guessed_type [ns_guesstype $full_filename]
    if { $guessed_type == "image/jpeg" } {
	catch { set what_aolserver_told_us [ns_jpegsize $full_filename] }
    } elseif { $guessed_type == "image/gif" } {
	catch { set what_aolserver_told_us [ns_gifsize $full_filename] }
    }
    return $what_aolserver_told_us
}

proc_doc ad_decorate_side {} "IF side graphics are enabled AND a graphics URL is spec'd for the current THEN this returns an IMG ALIGN=RIGHT with width and height tags.  Otherwise return empty string." {
    # we use a GLOBAL variable (shared by procs in a thread) as opposed to 
    # an ns_share (shared by many threads)
    global sidegraphic_displayed_p
    if ![ad_parameter EnabledP sidegraphics 0] {
	return ""
    }
    # let's see if this URL even has a side graphic
    set graphic_url [ad_parameter [ns_conn url] sidegraphics]
    if [empty_string_p $graphic_url] {
	# no side graphic for this particular page
	return ""
    }
    # OK, the system is enabled and we've got a side graphic for this URL
    # we want to get WIDTH and HEIGHT tags
    set width_height_list [util_memoize "ad_image_size $graphic_url" 900]
    if ![empty_string_p $width_height_list] {
	set width [lindex $width_height_list 0]
	set height [lindex $width_height_list 1]
	set extra_tags "width=$width height=$height hspace=10 vspace=10"
    } else {
	set extra_tags ""
    }
    set sidegraphic_displayed_p 1
    return "<img align=right $extra_tags hspace=20 src=\"$graphic_url\">"
}
