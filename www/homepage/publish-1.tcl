# /homepage/publish-1.tcl

ad_page_contract {
    Allow the user to publish customized content types.

    @param filesystem_node The top directory displayed.

    @creation-date Jan 14 18:48:26 EST 2000
    @author mobin@mit.edu
    @cvs-id publish-1.tcl,v 3.3.2.4 2000/07/21 04:00:45 ron Exp

} {
    filesystem_node:notnull,naturalnum
}


# ------------------------------ initialization codeBlock ----

set user_id [ad_maybe_redirect_for_registration]

set new_type_id [db_string new_type_id {
    select users_type_id_seq.nextval from dual
}]

db_release_unused_handles

# ------------------------------ htmlGeneration codeBlock ----

set dialog_body "Provide characteristics of the new content:<br><form method=post action=publish-2> \
  <input type=hidden name=filesystem_node value=$filesystem_node> \
  <input type=hidden name=new_type_id value=$new_type_id> \
  <table border=0 cellpadding=15> \
    <tr> \
      <th align=left>Content type: </td> \
      <td><input type=text size=16 name=content_type><br>(e.g. book)</td></tr> \
    <tr> \
      <th align=left>Very short name: </td> \
      <td><input type=text size=16 name=very_short_name><br>(e.g. nerdguide)</td></tr> \
    <tr> \
      <th align=left>Full name: </td> \
      <td><input type=text size=30 name=full_name><br>(e.g. Mobin's Guide to Becoming a Better Nerd)</td></tr> \
    <tr> \
      <th align=left>Subsections: </td> \
      <td><input type=text size=30 name=sub_section><br>(e.g. for a book, this should be `chapter')</td></tr> \
  </table> \
  <table border=0 cellpadding=0> \
  <tr> \
  <td><input type=submit value=Okay></form></td> \
  <td><form method=get action=index> \
  <input type=hidden name=filesystem_node value=$filesystem_node> \
  <input type=submit value=Cancel></form></td> \
  </tr> \
  </table>"

ad_returnredirect "dialog-class?title=Content Management&text=$dialog_body"
return

