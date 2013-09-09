# /www/bboard/admin-bozo-pattern-edit.tcl
ad_page_contract {
    Form to edit an existing bozo pattern

    @param topic_id the ID of the bboard topic
    @param topic the name of the bboard topic
    @param the_regexp the regular expression that is the bozo pattern

    @cvs-id admin-bozo-pattern-edit.tcl,v 3.2.2.4 2000/09/22 01:36:42 kevin Exp
} {
    topic_id
    topic
    the_regexp:allhtml
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
where  bt.topic_id=:topic_id
and    bt.primary_maintainer_id = u.user_id"]} {
    [bboard_return_cannot_find_topic_page]
    return
}


# get the regexp information
set the_regexp_old $the_regexp

set selection [ns_set create]
if {![db_0or1row bozo_pattern "
select scope, message_to_user, creation_comment 
from   bboard_bozo_patterns 
where  topic_id=:topic_id
and the_regexp = :the_regexp" -column_set selection]} {

    ad_return_error "No expression $the_regexp" "\"$the_regexp\"
is not a regular expression in the topic $topic.  Perhaps
it was edited or deleted."
   return
}

set message_to_user [ns_set get $selection message_to_user]
set creation_comment [ns_set get $selection creation_comment]

append page_content "<html>
<head>
<title>Edit Bozo Pattern \"$the_regexp\" in $topic</title>
</head>
<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>

<h2>Edit Bozo Pattern \"$the_regexp\"</h2>

in <a href=\"admin-home?[export_url_vars topic]\">$topic</a>

<hr>

<form method=POST action=\"admin-bozo-pattern-edit-2\">
[export_form_vars topic topic_id the_regexp_old]

<table>
<tr>
  <td>Regular Expression
  <td><input type=text name=the_regexp size=30 [export_form_value the_regexp]>
      <font size=-1>(lowercase)</font>
</tr>
<tr>
  <td>Scope
  <td>[bt_mergepiece "<select name=scope>
        <option value=\"both\">look in both subject and body</option>
        <option value=\"one_line\">look only in the subject line</option>
        <option value=\"message\">look only in the body</option>
      </select>" $selection]
</tr>
<tr>
  <td>Message to User
  <td><textarea name=message_to_user wrap=soft rows=8 cols=60>[ns_quotehtml $message_to_user]</textarea>
  </td>
</tr>
<tr>
  <td>Comment to other administrators<br><font size=-1>(optional)</font>
  <td><textarea name=creation_comment wrap=soft rows=8 cols=60>[ns_quotehtml $creation_comment]</textarea>
  </td>
</tr>

</table>

<p>
<center>
<input type=submit value=\"Edit\">
</center>

</form>

<br>
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