<%
ad_page_contract {
    /www/doc/standards.adp
    
    ACS standards
    
    @author  michael@arsdigita.com
    @created March 2000
    @cvs-id  standards.adp,v 3.7.2.6 2000/07/29 20:36:34 ron Exp
}

ad_proc proc_doc_link { proc_name } {} {
    return "<a href=\"proc-one?[export_url_vars proc_name]\"><code>$proc_name</code></a>"
}
%>

<html>
<head>

<title>Standards</title>
<style type="text/css">
BODY {
  background-color: #FFFFFF;
  color: #000000;
}
</style>

</head>

<body>

<h2>Standards</h2>

for the <a href=""">ArsDigita Community System</a>

<hr>

To ensure consistency (and its collateral benefit, maintainability),
we define and adhere to standards in the following areas:

<ul>
<li><a href="#file_naming">File Naming</a>
<li><a href="#file_header">File Headers and Page Input</a>
<li><a href="#page_construction">Page Construction</a>
<li><a href="#tcl_library_file">Tcl Library</a>
<li><a href="#data_modeling">Data Modeling</a>
<li><a href="#documentation">Documentation</a>
</ul>

<a name="file_naming"><h3>File Naming</h3></a>

Under the page root (and the template root if using the <a
href="style">Style package</a>):

<ul>

<li>For naming files that enable a specific action on an object, use
the convention:

<blockquote>
<code><em>object</em>-<em>verb</em>.<em>extension</em></code>
</blockquote>

For example, the page to erase a user's portrait from the database is
<code>/admin/users/portrait-erase.tcl</code>.

<p>

<li>For naming files that display the properties of one object (rather
than letting the user take a specific action), simply omit the verb,
and use the convention:

<blockquote>
<code><em>object</em>.<em>extension</em></code>
</blockquote>

For example, the page to view the properties of an
<href="ecommerce">ecommerce</a> product is
<code>/ecommerce/product.tcl</code>.

<p>

<li>Typically, a module deals with one primary type of object, e.g.,
the Bookmarks module deals mainly with bookmarks. Since the user pages
for the Bookmarks module live in the <code>/bookmarks/</code>
directory, it would be redundant to name the page for editing a
bookmark <code>bookmark-edit.tcl</code> (which would result in the URL
<code>bookmarks/bookmark-edit.tcl</code>. Instead, we omit the object
type, and use the convention:

<blockquote>
<code><em>verb</em>.<em>extension</em></code>
</blockquote>

Thus, the page to edit a bookmark is <code>/bookmarks/edit.tcl</code>.

<p>

<li>Similarly, for naming files that display the properties of one
primary-type object, use the convention:

<blockquote>
<code>one.<em>extension</em></code>
</blockquote>

For example, the page to view one bookmark is
<code>/bookmarks/one.tcl</code>.

<p>

<li>For naming files in a page flow, use the convention:

<p>

<ul>
<li><code><em>foobar</em>.<em>extension</em></code> (Step 1)
<li><code><em>foobar</em>-2.<em>extension</em></code> (Step 2)
<li>...
<li><code><em>foobar</em>-<em>N</em>.<em>extension</em></code> (Step N)
</ul>

<p>

where <code><em>foobar</em></code> is determined by the above
rules.

<p>

Typically, we build three-step page flows:

<p>

<ol>

<li>Present a form to the user

<li>Present a confirmation page to the user

<li>Perform the database transaction, then redirect

</ol>

<p>

<li>Put data model files in <code>/www/doc/sql</code>, and name them
using the convention:

<blockquote>
<code><em>module</em>.sql</code>
</blockquote>

</ul>

In the Tcl library directory:

<ul>

<li>For files that contain module-specific procedures, use the
convention:

<blockquote>
<code><em>module</em>-procs.tcl</code>
</blockquote>

<li>For files that contain procedures that are part of the core ACS,
use the convention:

<blockquote>
<code>ad-<em>description</em>-procs.tcl</code>
</blockquote>

</ul>

<h3>URLs</h3>

File names also appear <em>within</em> pages, as linked URLs and
form targets. When they do, always use <a href="abstract-url">abstract
URLs</a> (e.g., <code>user-delete</code> instead of
<code>user-delete.tcl</code>), because they enhance maintainability.

<p>

Similarly, when linking to the index page of a directory, do not
explicitly name the index file (<code>index.tcl</code>,
<code>index.adp</code>, <code>index.html</code>, etc.). Instead, use
just the directory name, for both relative links
(<code>subdir/</code>) and absolute links
(<code>/top-level-dir/</code>). If linking to the directory in which
the page is located, use the empty string (<code>""</code>), which
browsers will resolve correctly.

<a name="file_header"><h3>File Headers and Page Input</h3></a>

Include the appropriate standard header in all scripts.  The first
line should be a comment specifying the file path relative to the
ACS root directory.  e.g.

<pre>
# /www/index.tcl
</pre>

or

<pre>
# /tcl/module-defs.tcl
</pre>


<p>For static content files (html or adp), include a CVS identification tag as a
comment at the top of the file, e.g.  

<pre>
&lt;!-- standards.adp,v 3.7.2.6 2000/07/29 20:36:34 ron Exp --&gt;
</pre>


<h4>Using ad_page_contract</h4>

For non-library Tcl files (those not in the private Tcl directory),  use
<%= [proc_doc_link ad_page_contract] %>  after the file path comment
(this supersedes <%= [proc_doc_link set_the_usual_form_variables] %> and 
<%= [proc_doc_link ad_return_complaint] %>).
Here is an example of using ad_page_contract, which serves both 
documentation and page input validation purposes:

<blockquote>
<pre><code>
# www/register/user-login-2.tcl

ad_page_contract {
    Verify the user's password and issue the cookie.
    
    @param user_id The user's id in users table.
    @param password_from_from The password the user entered.
    @param return_url What url to return to after successful login.
    @param persistent_cookie_p Specifies whether a cookie should be set to keep the user logged in forever.
    @author John Doe (jdoe@arsdigita.com)
    @cvs-id standards.adp,v 3.7.2.6 2000/07/29 20:36:34 ron Exp
} {
    user_id:integer,notnull
    password_from_form:notnull
    {return_url {[ad_pvt_home]}}
    {persistent_cookie_p f}
}
</code></pre>
</blockquote>

<p>

Salient features of <code>ad_page_contract</code>:

<ul>

<li>A mandatory documentation string is the first argument. This has
the standard form with javadoc-style @author, @cvs-id, etc. 

<li>The second argument specifies the page
inputs. The syntax for switches/flags (e.g. multiple-list, array,
etc.) uses a <b>colon</b> (:) followed by any number of <b>flags</b>
separated by commas (,),
e.g. <code>foo:integer,multiple,trim</code>. In particular, <code>multiple</code> and
<code>array</code> are the flags that correspond to the old
<code>ad_page_variables</code> flags.

<li>There are new flags: <code>trim</code>, <code>notnull</code> and
<code>optional</code>. They do what you'd expect; values will not be
trimmed, unless you mark them for it; empty strings are valid input, unless
you specify notnull; and a specified variable will be considered required,
unless you declare it as optional.

<li>It can now do validation for you; the flags <code>integer</code>
and <code>sql_identifier</code> will make sure that the values
supplied are integers/sql_identifiers. The <code>integer</code> flag
will also trim leading zeros. Note that unless you specify
<code>notnull</code>, both will accept the empty string.

<li>Note that <code>ad_page_contract</code> does not generate
QQvariables, which were automatically created by ad_page_variables and
set_the_usual_form_variables. The use of bind variables makes such
previous variable syntax obsolete.

</ul>

<p>&nbsp;
<p>

<h4>Using ad_library</h4>


For shared Tcl library files, use <%= [proc_doc_link ad_library] %> after
the file path comment. Its only argument is a doc_string in the standard (javadoc-style)
format, like <code>ad_page_contract</code>. Don't forget to put the
@cvs-id in there.  Here is an example of using ad_library:

<blockquote>
<pre><code>
# tcl/wp-defs.tcl

ad_library {
    Provides helper routines for the Wimpy Point module.

    @author John Doe (jdoe@arsdigita.com)
    @cvs-id standards.adp,v 3.7.2.6 2000/07/29 20:36:34 ron Exp
}
</code></pre>
</blockquote>

<p>&nbsp;
<p>

<h4>Non-Tcl Files</h4>

For SQL and other non-Tcl source files, the following file header structure is recommended:

<blockquote>
<pre><code>
-- <em>path relative to the ACS root directory</em>
--
-- <em>brief description of the file's purpose</em>
--
-- <em>author</em>
-- <em>created</em>
--
-- <a href="http://www.loria.fr/~molli/cvs/doc/cvs_12.html#SEC93">&#36;Id&#36;</a>
</code></pre>
</blockquote>

Of course, replace "<code>--</code>" with the comment delimiter
appropriate for the language in which you are programming.

<p>&nbsp;
<p>


<a name="page_construction"><h3>Page Construction</h3></a>

Construct the page as one Tcl variable (name it
<code>page_content</code>), and then send it back to the browser with
one call to <code>doc_return</code>, which will call
db_release_unused_handles prior to executing ns_return, effectively
combining the two operations.

<p>

For example:

<blockquote>
<pre>

set page_content "[ad_header "<em>Page Title</em>"]

&lt;h2&gt;<em>Page Title</em>&lt;/h2&gt;

&lt;hr&gt;

&lt;ul&gt;
"

db_foreach get_row_info {
    select row_information 
    from bar
} {
    append page_content "&lt;li&gt;<em>row_information</em>\n"
}

append page_content "&lt;/ul&gt;

[ad_footer]"

doc_return 200 text/html $page_content
</pre>
</blockquote>

<p>

The old convention was to call <code>ReturnHeaders</code> and
then <code>ns_write</code> for each distinct chunk of the page. This
approach has the disadvantage of tying up a scarce and valuable
resource (namely, a database handle) for an unpredictable amount of
time while sending packets back to the browser, and so it should be
avoided in most cases. (On the other hand, for a page that requires an
expensive database query, it's better to call

<%= [proc_doc_link ad_return_top_of_page] %>

first, so that the user is not left to stare at an empty page while
the query is running.)

<p>

Local procedures (i.e., procedures defined and used only within one
page) should be prefixed with "<code><em>module</em>_</code>" and
should be used rarely, only when they are exceedingly useful.

<p>

All files that prepare HTML to display should end with [ad_footer] or
[<em>module</em>_footer].  If your module requires its own footer,
this footer should call ad_footer within it.  Why?  Because when we
adapt the ACS to a new site, it is often the case that the client will
want a much fancier display than the ACS standard.  We like to be able to
edit ad_header (which quite possibly can start a &lt;table&gt;) and
ad_footer (which may need to end the table started in ad_footer) to
customize the look and feel of the entire site.

<a name="tcl_library_file"><h3>Tcl Library Files</h3></a>

<p>

Further standards for Tcl library files are under discussion; we plan to 
include naming conventions for procs.



<a name="data_modeling"><h3>Data Modeling</h3></a>

Under discussion; will include: standard columns, naming conventions
for constraints.

<ul>

<li>If you need to store the names of database tables as column values
(e.g., in the <code>on_which_table</code> column of the
<code>general_permissions</code> table), normalize them into upper
case (following the convention established in the Oracle data
dictionary).

</ul>

<a name="documentation"><h3>Documentation</h3></a>

Under discussion.

</font>

<hr>

<a href="mailto:michael@arsdigita.com">
<address>michael@arsdigita.com</address>
</a>

<a href="mailto:aure@arsdigita.com">
<address>aure@arsdigita.com</address>
</a>

</body>
</html>
