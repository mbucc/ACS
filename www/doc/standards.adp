<%
#
# /www/doc/standards.adp
#
# ACS standards
#
# michael@arsdigita.com, March 2000
#
# $Id: standards.adp,v 3.3.2.5 2000/03/17 08:29:54 michael Exp $
#

proc proc_doc_link { proc_name } {
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
<li><a href="#file_header">File Headers</a>
<li><a href="#page_input">Page Input</a>
<li><a href="#page_construction">Page Construction</a>
<li><a href="#tcl_library">Tcl Library</a>
<li><a href="#data_modeling">Data Modeling</a>
<li><a href="#tcl_library_file">Documentation</a>
</ul>

<a name="file_naming"><h3>File Naming</h3></a>

Under the page root (and the template root if using the <a
href="style">Style package</a>):

<ul>

<li>For naming files that enable a specific action on an object, use
the convention:

<blockquote>
<code><em>object_type</em>-<em>verb</em>.<em>extension</em></code>
</blockquote>

For example, the page to erase a user's portrait from the database is
<code>/admin/users/portrait-erase.tcl</code>.

<p>

<li>For naming files that display the properties of one object (rather
than letting the user take a specific action), simply omit the verb,
and use the convention:

<blockquote>
<code><em>object_type</em>.<em>extension</em></code>
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

<a name="file_header"><h3>File Headers</h3></a>

Include the standard header in all source files:

<blockquote>
<pre><code>
# <em>path from server home</em>/<em>filename</em>
#
# <em>Brief description of the file's purpose</em>
#
# <em>author's email address</em>, <em>file creation date</em>
#
# <a href="http://www.loria.fr/~molli/cvs/doc/cvs_12.html#SEC93">&#36;Id&#36;</a>
</code></pre>
</blockquote>

<p>

Of course, replace "<code>#</code>" with the comment delimiter
appropriate for the language in which you are programming, e.g.,
"<code>--</code>" for SQL and PL/SQL.

<p>

Previously, the standard for headers in files under the page root was
to specify a path relative to the page root, e.g.
<code>/index.tcl</code>, unlike all other files in the ACS, where the
path was relative to the server home directory,  e.g.
<code>/tcl/bboard-defs.tcl</code>. The current standard eliminates
this inconsistency, so that the path in every file header (under the
page root or not) is relative to the server home directory:
<code>/www/index.tcl</code> instead of <code>/index.tcl</code>.

<a name="page_input"><h3>Page Input</h3></a>

In addition to the standard file header, each page should start by:

<ol>

<li>specifying the input it expects (in essence, its parameter list)
with a call to <%= [proc_doc_link ad_page_variables] %>
(which supersedes <%= [proc_doc_link set_the_usual_form_variables] %>)

<li>validating its input with a call to <%= [proc_doc_link page_validation] %>
(which supersedes <%= [proc_doc_link ad_return_complaint] %>)

</ol>

<a name="page_construction"><h3>Page Construction</h3></a>

Construct the page as one Tcl variable (name it
<code>page_content</code>), and then send it back to the browser with
one call to <code>ns_return</code>. Make sure to release any database
handles (and any other acquired resources, e.g., filehandles) before
the call.

<p>

For example:

<blockquote>
<pre>set db [ns_db gethandle]

set page_content "[ad_header "<em>Page Title</em>"]

&lt;h2&gt;<em>Page Title</em>&lt;/h2&gt;

&lt;hr&gt;

&lt;ul&gt;
"

set selection [ns_db select $db <em>sql</em>]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query

    append page_content "&lt;li&gt;<em>row information</em>\n"
}

append page_content "&lt;/ul&gt;

[ad_footer]"

ns_db releasehandle $db

ns_return 200 text/html $page_content
</pre>
</blockquote>

<p>

Previously, the convention was to call <code>ReturnHeaders</code> and
then <code>ns_write</code> for each distinct chunk of the page. This
approach has the disadvantage of tying up a scarce and valuable
resource (namely, a database handle) for an unpredictable amount of
time while sending packets back to the browser, and so, it is to be
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
adopt the ACS to a new site, it is often the case that the client will
want a much fancier display than ACS standard.  We like to be able to
edit ad_header (which quite possibly can start a &lt;table&gt;) and
ad_footer (which may need to end the table started in ad_footer) to
customize the look and feel of the entire site.

<a name="tcl_library_file"><h3>Tcl Library Files</h3></a>

After the file header, the first line of each Tcl library file should
be a call to <%= [proc_doc_link util_report_library_entry] %>.

<p>

The last line of each Tcl library file should be a call to
<%= [proc_doc_link util_report_successful_library_load] %>.

<p>

Under discussion; will include: proc naming conventions

<a name="data_modeling"><h3>Data Modeling</h3></a>

Under discussion; will include: standard columns, naming conventions
for constraints.

<a name="doc"><h3>Documentation</h3></a>

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
