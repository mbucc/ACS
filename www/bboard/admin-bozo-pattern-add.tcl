# /www/bboard/admin-bozo-pattern-add.tcl
ad_page_contract {
    Adds a new bozo pattern for a bboard forum

    @param topic the name of the bboard topic
    @param topic)id the ID of the bboard topic

    @cvs-id admin-bozo-pattern-add.tcl,v 3.2.2.3 2000/09/22 01:36:41 kevin Exp
} {
    topic:notnull
    topic_id:integer,notnull
}

# -----------------------------------------------------------------------------

if  {[bboard_get_topic_info] == -1} {
    return
}

if {[bboard_admin_authorization] == -1} {
	return
}

# cookie checks out; user is authorized

if { ![db_0or1row maintainer_info "
select bt.*,u.email as maintainer_email, 
       u.first_names || ' ' || u.last_name as maintainer_name, 
       presentation_type
from   bboard_topics bt, users u
where  bt.topic_id = :topic_id
and    bt.primary_maintainer_id = u.user_id"]} {
    [bboard_return_cannot_find_topic_page]
    return
}


append page_content "
[ad_admin_header "Add Bozo Pattern to $topic"]

<h2>Add Bozo Pattern</h2>

for <a href=\"admin-home?[export_url_vars topic topic_id]\">$topic</a>

<hr>

<form method=POST action=\"admin-bozo-pattern-add-2\">
[export_form_vars topic topic_id]

<table>
<tr>
  <td>Regular Expression
  <td><input type=text name=the_regexp size=30>
      <font size=-1>(lowercase)</font>
</tr>
<tr>
  <td>Scope
  <td><select name=scope>
        <option value=\"both\" SELECTED>look in both subject and body</option>
        <option value=\"one_line\">look only in the subject line</option>
        <option value=\"message\">look only in the body</option>
      </select>
</tr>
<tr>
  <td>Message to User
  <td><textarea name=message_to_user wrap=soft rows=8 cols=60></textarea>
  </td>
</tr>
<tr>
  <td>Comment to other administrators<br><font size=-1>(optional)</font>
  <td><textarea name=creation_comment wrap=soft rows=8 cols=60></textarea>
  </td>
</tr>

</table>

<p>
<center>
<input type=submit value=\"Add\">
</center>

</form>

<br>
<br>

<blockquote>

Note: the regular expression should be in Tcl format.  If you just
want to match for a particular word, you need only type that word.  If
you want something fancier, you probably have to read

<a href=\"http://www.amazon.com/exec/obidos/ASIN/1565922573/photonetA\">Mastering Regular Expressions</a> (Friedl; O'Reilly)

</blockquote>

[bboard_footer]
"

doc_return  200 text/html $page_content