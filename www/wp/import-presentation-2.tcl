# /wp/import-presentation-2.tcl

ad_page_contract  {
    Imports a presentation from another server.
    @author Alen Zekulic (alen@ultra.hr)
    @creation-date 2000-09-11
    @cvs-id import-presentation-2.tcl,v 1.1.2.4 2000/09/24 15:16:07 azekulic Exp
} { 
    url:notnull,trim
    email:optional
    password:optional
}

ad_maybe_redirect_for_registration
set user_id [ad_verify_and_get_user_id]

regsub {(([0-9]+)\.wimpy)?$} $url "" url
set complete_url "$url/export-presentation?[export_url_vars email password]"

if [catch {array set presentation_properties [ns_httpget "$complete_url"]} errmsg] {
   ad_return_complaint 1 "<li>Import failed, here is the exact error message: <pre>$errmsg</pre></li>\n"
   return
}

if [exists_and_not_null presentation_properties(status_code)] {
   if {![wp_check_status_code $presentation_properties(status_code) $url $email $password]} {
     return
   }
} else {
   ad_return_error "Unexpected Result" "We received an unexpected result when querying for the status of requested presentation. It would be helpful if you could email <a href=\"mailto:[ad_system_owner]\">[ad_system_owner]</a> with the events that led up to this occurrence."
   return
}

set page_content "
[wp_header_form "method=post action=import-presentation-3" \
    [list "" "WimpyPoint"] "Presentation info"]
[export_form_vars url email password]
<p>
<h3>Requested Presentation</h3>
<p>
<ul>
 <li><font color=blue>$presentation_properties(title)</font>, 
      created on $presentation_properties(creation_date).
     \[ <input type=submit value=import> | <a href=\"index\">cancel</a> \] </li>
</ul>
</form>

[wp_footer]
"
doc_return  200 "text/html" $page_content
