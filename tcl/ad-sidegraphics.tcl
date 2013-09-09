# /tcl/ad-sidegraphics.tcl

ad_library {
    @author  Philip Greenspun (philg@arsdigita.com)
    @created April 21, 1999
    @cvs-id  ad-sidegraphics.tcl,v 3.0.14.7 2000/08/25 18:58:38 jong Exp
}

proc_doc ad_image_size {graphics_url} {

    Returns a Tcl list of WIDTH and HEIGHT of image, works for both JPEG
    and GIF.  We need our own proc because AOLserver is stupid and has
    separate API calls for JPEG and GIF.

} { 
    if [string match "http://*" [string tolower $graphics_url]] {
	# this is a image on a foreign server, we won't be able to 
	# figure out its size 
	return ""
    }

    # call ns_gifsize or ns_jpegsize, as appropriate
    set full_filename [ns_info pageroot]$graphics_url

    switch [ns_guesstype "$full_filename"] {

	image/jpeg {
	    set what_aolserver_told_us [ns_jpegsize $full_filename]
	}

	image/gif {
	    set what_aolserver_told_us [ns_gifsize $full_filename]
	}

	default {
	    set what_aolserver_told_us ""
	}
    }

    return $what_aolserver_told_us
}

proc_doc ad_decorate_side {} {

    If side graphics are enabled and a graphics URL is spec'd for the
    current then this returns an <img align=right> with width and height
    tags.  Otherwise it returns an empty string.  

} {
    # we use a GLOBAL variable (shared by procs in a thread) as opposed to 
    # an ns_share (shared by many threads)
    global sidegraphic_displayed_p
    if ![ad_parameter EnabledP sidegraphics 0] {
	return ""
    }

    # let's see if this URL even has a side graphic
    set graphic_url [ad_parameter [ad_conn full_url] sidegraphics]
    if [empty_string_p $graphic_url] {
	# no side graphic for this particular page
	return ""
    }
    # OK, the system is enabled and we've got a side graphic for this URL
    # we want to get WIDTH and HEIGHT tags
    set width_height_list [util_memoize "ad_image_size $graphic_url" 900]
    if ![empty_string_p $width_height_list] {
	set width  [lindex $width_height_list 0]
	set height [lindex $width_height_list 1]
	set extra_tags "width=$width height=$height hspace=10 vspace=10"
    } else {
	set extra_tags ""
    }
    set sidegraphic_displayed_p 1
    return "<img align=right $extra_tags hspace=20 src=\"$graphic_url\">"
}
