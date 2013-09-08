ad_page_contract {
    Stops watching a particular file.
   
    @param watch_file The file to stop watching.
    @author Jon Salz [jsalz@arsdigita.com]
    @date 17 April 2000
    @cvs-id file-watch-cancel.tcl,v 1.2.2.2 2000/07/21 03:55:42 ron Exp
} {
    watch_file
}

doc_body_append "[apm_header "Cancel a Watch"]
"

catch { nsv_unset apm_reload_watch $watch_file }

doc_body_append "No longer watching the following file:<ul><li>$watch_file</ul>

<a href=\"/admin/apm/\">Return to the Package Manager</a>

[ad_footer]
"

