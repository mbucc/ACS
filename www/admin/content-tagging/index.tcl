# File: /www/admin/content-tagging/index.tcl
ad_page_contract {
    Displays the Content Tagging Package Page
    
    @param none
    @author unknown
    @cvs-id index.tcl,v 3.2.2.5 2000/09/22 01:34:35 kevin Exp
} {
}

set title "Content Tagging"

set page_content "[ad_admin_header "$title Package"]

<h2>$title Package</h2>

[ad_admin_context_bar "$title Package"]

<hr>

Documentation:  <a href=\"/doc/content-tagging\">/doc/content-tagging.html</a>

<h3>Dictionary</h3>

<ul>
<li><a href=\"all\">all of the words</a>

<form action=lookup>
<li>word to look up:
<input type=text size=20 name=word>
<input type=submit value=Submit>
</form>

</ul>

<form action=add>
Enter words(s) to add to the tagged dictionary:<br>
<textarea name=words rows=4 cols=60></textarea>
<center>
<select name=tag>
<option value=1>Rated PG</option>
<option value=3>Rated R</option>
<option value=7>Rated X</option>
</select>
<input type=submit value=Add>
</center>
</form>

<h3>Historical Naughtiness</h3>

<ul>
<li><a href=\"by-user\">by user</a>
</ul>

<h3>Test</h3>

<form action=test>
Phrase to test:
<br>
<textarea name=testarea rows=8 cols=60>
</textarea>
<br>
<input type=hidden name=table_name value=test> 
<input value=test  type=hidden name=the_key>
<input value=test  type=hidden name=key_name>
<center>
<input type=submit value=\"Test Text\">
</center>
</form>

[ad_admin_footer]
"

doc_return  200 text/html $page_content

