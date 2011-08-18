# $Id: mapping-change.tcl,v 3.0 2000/02/06 03:27:46 ron Exp $
set_the_usual_form_variables

# glob_pattern

ReturnHeaders

set db [ns_db gethandle]

set selection [ns_db 1row $db "select canonical_foreign_url, search_engine_name, search_engine_regexp from referer_log_glob_patterns where glob_pattern = '$QQglob_pattern'"]
set_variables_after_query

ns_write "[ad_admin_header "Edit Lumping Pattern"]

<h2>Edit a Lumping Pattern</h2>

in the <a href=\"report.tcl\">referral tracking section</a> 
of <a href=\"/admin/\">[ad_system_name] administration</a>

<hr>

<form action=mapping-change-2.tcl method=post>
[export_form_vars glob_pattern]

Referer headers matching the pattern: (Example: http://www.altavista.com*) <br> 
<input type=text name=new_glob_pattern size=70 maxlength=250 value=\"[philg_quote_double_quotes $glob_pattern]\">

<p>


will be lumped together in reports under the URL: (Example: http://www.altavista.com) <br>
<input type=text name=canonical_foreign_url size=70 maxlength=250 value=\"[philg_quote_double_quotes $canonical_foreign_url]\">

<p>

If you are  trying lump together referrals from a search
engine, you probably also want to fill in these additional fields.
<p>
Name of search engine: <br> 
<input type=text name=search_engine_name size=30 maxlength=30 value=\"[philg_quote_double_quotes $search_engine_name]\"><br>
(this is for reports, e.g., \"AltaVista\") 

<p>

Tcl Regular Expression to pull out query string:
<input type=text name=search_engine_regexp size=40 maxlength=200 value=\"[philg_quote_double_quotes $search_engine_regexp]\"><br>


<p>

Explaining REGEXPs is beyond the scope of this document.  There is a
comprehensive book on the subject: <cite>Mastering Regular
Expressions</cite> (Friedl 1997; O'Reilly).  The idea is that you give
the computer to figure out which part of the referer header contains
the string typed.

<p>

Here's an example log entry:

<blockquote>
<code>
139.134.23.10 - - \[28/Nov/1998:19:05:16 -0500\] \"GET /WealthClock HTTP/1.0\" 200 3609 http://www.altavista.com/cgi-bin/query?pg=q&kl=XX&q=how+Bill+Gates+began&search=Search \"Mozilla/2.0 (compatible; MSIE 3.0; Windows 95) via NetCache version NetApp Release 3.2.1R1D12: Wed Oct 28 08:37:31 PST 1998\"
</code>
</blockquote>

The referer header is 

<blockquote>
<code>
http://www.altavista.com/cgi-bin/query?pg=q&kl=XX&q=how+Bill+Gates+began&search=Search
</code>
</blockquote>

It looks like the query string starts with a <code>q=</code> and ends
with either a space or an ampersand.  A regular expression to match
this would be

<blockquote>
<code>
q=(\[^& \]+)
</code>
</blockquote>

<p>

<center>

<input type=submit name=submit value=\"Update Mapping\"> 
<input type=submit name=submit value=\"Delete Mapping\"> </form>

</center>

[ad_admin_footer]
"

