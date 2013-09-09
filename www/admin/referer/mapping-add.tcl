# /admin/referer/mapping-add.tcl
#

ad_page_contract {
    serves a form to the site administrator; takes no action
    @cvs-id mapping-add.tcl,v 3.3.2.4 2000/09/22 01:35:59 kevin Exp
    @author Philip Greenspun (philg@mit.edu) in 1998
} {
}


set page_content "[ad_admin_header "Add Lumping Pattern"]
<h2>Add Lumping Pattern</h2>

[ad_admin_context_bar [list "" "Referrals"] [list "mapping" "Lumping Patterns"] "Add"]

<hr>

<form action=mapping-add-2 method=post>

Referer headers matching the pattern: <i>(Example: http://www.altavista.com*)</i> <br>
<input type=text name=glob_pattern size=70 maxlength=250><p>

will be lumped together in reports under the URL: <i>(Example: http://www.altavista.com)</i> <br>

<input type=text name=canonical_foreign_url size=70 maxlength=250><br>
<p>

<i>Note: lumping is done using the Tcl GLOB facility.  The basic idea is
that * matches 0 or more characters, so \"*photo.net*\" would match
any referral coming from a server with photo.net in its hostname, e.g., 
\"db.photo.net\".</i>

<P>

If what you're trying to do is lump together referrals from a search
engine, you probably also want to fill in these additional fields.  If
you are successful, not only will the ArsDigita Community System
record the referrals but it will also capture the query strings and
store them in the database.  So, for example, you would be able to see
that users of Lycos are coming to this site looking for information on
\"Nikon history\" or that users of AltaVista queried for \"supermodels
on rollerskates\" and were sent here.

<P>

Name of search engine:  <input type=text name=search_engine_name size=25 maxlength=30>
<br>
(this is for reports, e.g., \"AltaVista\")

<P>

Tcl Regular Expression to pull out query string:  
<input type=text name=search_engine_regexp size=40 maxlength=200>

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
<input type=submit name=submit value=\"Add Pattern\">
</center>
</form>

[ad_admin_footer]
"

doc_return  200 text/html $page_content

