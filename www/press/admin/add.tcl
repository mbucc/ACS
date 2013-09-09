# /www/press/admin/add.tcl

ad_page_contract {

    Add a new press item
    
    @author  Ron Henderson (ron@arsdigita.com)
    @created December 1999
    @cvs-id  add.tcl,v 3.4.2.7 2000/09/22 01:39:05 kevin Exp
}

# Verify that this user is a valid administrator

set user_id [ad_verify_and_get_user_id]

if {![press_admin_any_group_p $user_id]} {
    ad_return_complaint 1 "<li>You are not authorized to access this page"
    return
}

# Give default values for some of the form variables

set publication_link "http://"
set article_link     "http://"
set important_p      "t"
set html_p           "f"

# Special formatting for a required form element

proc press_mark_required { varname } {
    return "<font color=red>$varname</font>"
}

# Get sample variables for the form

press_coverage_samples

# -----------------------------------------------------------------------------
# Ship it out

doc_return  200 text/html "
[ad_header "Add a Press Item"]

<h2>Add a Press Item</h2>

[ad_context_bar_ws [list "../" "Press"] [list "" "Admin"] "Add a Press Item"]

<hr>

<p>Use the following form to define your press coverage.  Note that
some fields are [press_mark_required "required"], while others may be
required depending on which template you choose (see the available
press coverage templates at the bottom of this page).  When you're done
click 'Preview' and we'll show what your press item will look like when
it's published by the press module.

<form method=post action=preview>
<input type=hidden name=target value=add-2>
<table>

[press_entry_widget [press_mark_required "Publication"] publication_name 30 "e.g. $sample_publication_name"]
[press_entry_widget "Link" publication_link 30 "e.g. $sample_publication_link"]

<tr>
<td align=right><b>[press_mark_required "Publication Date"]</b>:</td>
<td>[ad_dateentrywidget publication_date ""]</td>
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
  <textarea name=abstract cols=60 rows=10 wrap></textarea>
</td>
</tr>

<tr>
  <td></td>
  <td colspan=2>The above is formatted as: 
      [press_radio_widget html_p f "Plain Text"]&nbsp;
      [press_radio_widget html_p t "HTML"]
  </td>
</tr>

[press_scope_widget]
[press_template_widget]

<tr>
  <td align=right valign=top><b>Importance</b>:</td>
  <td colspan=2>
   [press_radio_widget important_p t \
	   "High (press item will not expire)"]&nbsp;<br>
   [press_radio_widget important_p f \
	   "Low (press item will expire in [press_active_days] days)"]
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

