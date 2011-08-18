# $Id: index.tcl,v 3.0 2000/02/06 03:15:27 ron Exp $
ReturnHeaders

set title "Content Tagging"

ns_write "[ad_admin_header "$title Package"]

<h2>$title Package</h2>

[ad_admin_context_bar "$title Package"]

<hr>

Documentation:  <a href=\"/doc/content-tagging.html\">/doc/content-tagging.html</a>

<h3>Dictionary</h3>

<ul>
<li><a href=\"all.tcl\">all of the words</a>

<form action=lookup.tcl>
<li>word to look up:
<input type=text size=20 name=word>
<input type=submit value=Submit>
</form>

</ul>

<form action=add.tcl>
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
<li><a href=\"by-user.tcl\">by user</a>
</ul>

<h3>Test</h3>


<form action=test.tcl>
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
