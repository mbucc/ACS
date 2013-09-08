# /wp/import-presentation.tcl

ad_page_contract  {
    Allows the user to import a presentation from another server.
    @author Alen Zekulic (alen@ultra.hr)
    @creation-date 2000-09-11
    @cvs-id import-presentation.tcl,v 1.1.2.3 2000/09/24 15:16:07 azekulic Exp
} { 
    {url:optional,trim ""}
    {email:optional ""}
    {status:optional ""}
}

ad_maybe_redirect_for_registration
set user_id [ad_verify_and_get_user_id]

switch -- $status {
  private
    {set message "<h2>Private presentation</h2> 
          The requested presentation is private, please enter an email and password."}
  failed
    {set message "<h2>Authorization failed</h2> 
          The password you entered does not match our records."}
  default
    {set message "Please enter the URL of the table-of-contents page for the
                  presentation you wish to import.This URL probably looks like

                  <code>http://www.arsdigita.com/wp/display/82633/</code>."
    }
}

set page_content "
[wp_header_form "method=post action=import-presentation-2" \
  [list "" "WimpyPoint"] "Import Presentation"]
<p>
 $message
<p>
 <center><table>
  <tr><td align=right>URL:</td><td><input type=text name=url size=50 value=$url></td></tr>
  <tr><td align=right>Your email address:</td><td><input type=text name=email value=$email></td></tr>
  <tr><td align=right>Your password:</td><td><input type=password name=password></td></tr>
  <tr><td colspan=2 align=center><input type=submit value=\"Import\"></td></tr>
 </table></center>
</form>

[wp_footer]
"

doc_return  200 "text/html" $page_content
