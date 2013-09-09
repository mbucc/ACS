#/tcl/style-sheets.tcl
ad_library {
    @author ?
    @cvs-id style-sheets.tcl,v 3.2.2.1 2000/07/14 05:15:36 david Exp
}

proc_doc get_style_sheet { file_name_stub } { examines the http user_agent header, and depending on whether the user's browser is IE, netscape or other, appends -ie.css, -ns.css or .css to the file name sub supplied by the caller } {

    set user_agent [ns_set get [ns_conn headers] User-Agent]
	
    # IE browsers have MSIE and Mozilla in their user-agent header
    set internet_explorer_p [regexp -nocase "msie" $user_agent match]

    # Netscape browser just have Mozilla in their user-agent header
    if {$internet_explorer_p == 0} {
	if { [regexp -nocase "mozilla" $user_agent match] } {
            append file_name_stub "-ns.css"
	} else {
            append file_name_stub ".css"
	}
    } else {
        append file_name_stub "-ie.css"
    }

    return $file_name_stub
   

}




