# /www/press/admin/edit.tcl

ad_page_contract { 

    Edit a press item
    
    @author  Ron Henderson (ron@arsdigita.com)
    @created December 1999
    @cvs-id  edit.tcl,v 3.3.8.5 2000/09/22 01:39:07 kevin Exp
} {
    press_id:integer
}

set user_id [ad_verify_and_get_user_id]

# Initialize the form variables

if ![db_0or1row press_item "
select scope,
       group_id,
       important_p,
       publication_name,
       publication_link,
       to_char(publication_date,'yyyy-mm-dd') as publication_date,
       publication_date_desc,
       article_title,
       article_link,
       article_pages,
       abstract,
       html_p,
       template_id
from   press
where  press_id = $press_id"] {
    ad_return_error "An error occurred looking up press_id = $press_id"
    return
}

# Verify this user is authorized to edit this press item

if {![press_admin_p $user_id $group_id]} {
    ad_return_complaint 1 "<li>You are not authorized to access this page"
    return
}

if {[empty_string_p $publication_link]} {
    set publication_link "http://"
}

if {[empty_string_p $article_link]} {
    set article_link "http://"
}

# Special formatting for a required form element

proc press_mark_required { varname } {
    return "<font color=red>$varname</font>"
}

# Get sample variables for the form

press_coverage_samples

# -----------------------------------------------------------------------------
# Ship out the form

doc_return  200 text/html "
[ad_header "Edit a Press Item"]

<h2>Edit a Press Item</h2>

[ad_context_bar_ws [list "../" "Press"] [list "" "Admin"] "Edit"]
<hr>

<p>Please update the information for this press item.  Note that
some fields are [press_mark_required "required"] for all press coverage,
while others may be required depending on which template you choose.</p>

<form method=post action=preview>
<input type=hidden name=target value=edit-2>
<input type=hidden name=press_id value=$press_id>
<table>

[press_entry_widget [press_mark_required "Publication"] publication_name 30 "e.g. $sample_publication_name"]
[press_entry_widget "Link" publication_link 30 "e.g. $sample_publication_link"]

<tr>
<td align=right><b>[press_mark_required "Publication Date"]</b>:</td>
<td>[ad_dateentrywidget publication_date $publication_date]</td>
</tr>
[press_entry_widget "Date Description" publication_date_desc 30 "e.g. $sample_publication_date_desc"]

<tr>
<td>&nbsp;</td>
</tr>

[press_entry_widget [press_mark_required "Article Title"] article_title 30 "e.g. $sample_article_title"]
[press_entry_widget "Link"  article_link  30 "e.g. $sample_article_link"]
[press_entry_widget "Pages" article_pages 30 "e.g. $sample_article_pages"]

<tr>
<td align=right valign=top><b>Abstract</b>:</td>
<td colspan=2>
  <textarea name=abstract cols=60 rows=10 wrap>[ns_quotehtml $abstract]</textarea>
</td>
</tr>

<tr>
  <td></td>
  <td colspan=2>The above is formatted as: 
      [press_radio_widget html_p f "Plain Text"]&nbsp;
      [press_radio_widget html_p t "HTML"]
  </td>
</tr>

[press_scope_widget $group_id]
[press_template_widget $template_id]

<tr>
  <td align=right valign=top><b>Importance</b>:</td>
  <td colspan=2>
   [press_radio_widget important_p t \
	   "High (press will not expire)"]&nbsp;<br>
   [press_radio_widget important_p f \
	   "Low (press will expire in [press_active_days] days)"]
  </td>
</tr>

<tr>
<td>&nbsp;</td>
</tr>

<tr>
  <td></td>
  <td><input type=submit value=\"Preview\"></td>
</tr>

</table>
</form>

<hr>

<p>Press coverage templates:</p>

[press_template_list]

[ad_footer]"
