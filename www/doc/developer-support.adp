<%
ad_page_contract {

	@author ?
	@creation-date ?
	@cvs-id developer-support.adp,v 3.2.2.3 2000/08/01 00:21:09 chiao Exp

} {
}
%>

<html>
<head>
<title>Developer Support</title>
</head>

<body bgcolor=white text=black>
<h2>Developer Support</h2>

part of the <a href="">ArsDigita Community System</a>, by <a href="mailto:jsalz@mit.edu">Jon Salz</a>

<hr>

<ul>
<li>Admin interface: /www/admin/monitoring/request-info.tcl
<li>Procedures: /packages/developer-support-procs.tcl, with support in:
<ul>
<li>/tcl/ad-abstract-url.tcl
<li>/tcl/ad-defs.tcl.preload
<li>/tcl/ad-security.tcl.preload
</ul>
</ul>

<h3>The Big Picture</h3>

Software development is a big feedback loop: a developer writes something, tests it, and
then repeats until the results are satisfactory. It's important to streamline this cycle
by having a development environment which makes it easy to analyze what the software is
doing under the hood.

<h3>Peeking Under the Hood</h3>

<p>Our development environment previously consisted largely of Emacs, and <tt>tail -f
/web/servername/log/servername-error.log</tt>. Now this has been augmented:
<tt>ad_footer</tt> and <tt>ad_admin_footer</tt> now display a link entitled
<i>Developer Information</i>. (You can use the <tt>ds_link</tt> procedure to generate the
link yourself.) Following the link displays a screenful of information
including:

<ul>
<li>The times that the request started and ended, and its duration (with millisecond accuracy).
<li>The request parameters (method, url, query, headers, etc.).
<li>The output headers, if any.
<li>Information about all database queries performed while loading the page, including
their respective durations (with millisecond accuracy).
</ul>

<p>In addition, the ClientDebug facility of AOLserver 2 has been re-implemented in the
abstract URL system (which serves nearly all non-static pages).
If an error occurs while serving a page, a stack trace is printed out.

<p>Note that these nifty features pop up only when you are logged in as a site-wide
administrator! Revealing this information to anyone else would pose a huge security
risk.

<h3>The Report</h3>

<%

ad_call_proc_if_exists ds_comment "This is where comments are displayed."

if { [db_0or1row "select first_names from users where user_id = [ad_get_user_id]"] } {
    set greeting "$first_names, "
    ad_call_proc_if_exists ds_comment "Your first name is $first_names."
} else {
    set greeting ""
}

set db [ns_db gethandle]
db_with_handle db {
    set admin_p [ad_administrator_p $db]
}

if { [llength [info procs ds_link]] == 0 } {
    ns_adp_puts "
Developer support is not currently enabled on this server.
Here's <a href=\"developer-support-example\">an example of what the
report looks like</a>.
"
} elseif { $admin_p } {
    ns_adp_puts "
<p>$first_names, you are currently logged in as a site-wide administrator, so you can try it
out! To see the information regarding your request for this documentation page,
scroll down to the bottom of the page and click the <i>Developer Information</i>
link in the lower-right corner.
"
} else {
    ns_adp_puts "
<p>I would show you a demo, but you are not currently logged in as a site-wide
administrator. Here's <a href=\"developer-support-example\">an example of what the
report looks like</a>.
"
}
db_release_unused_handles
%>

<h3>Comments</h3>

Tired of using <tt>ns_log</tt> to instrument your code, then grokking the error log
to see what's wrong with your page? Use the <tt>ds_comment</tt> routine instead:

<blockquote><pre>ds_comment "Foo is $foo"</pre></blockquote>

Your comment will show up at the bottom of the page, beneath the <i>Developer Information</i>
link (but only for site-wide administrators). It will also be displayed on the
Developer Information page itself.

<p>Comments are displayed even if an error occurs in the page!

<h3>Enabling It</h3>

Add the following to your
<tt>parameters/yourservername.ini</tt> file:

<blockquote><pre>[ns/server/yourservername/acs/developer-support]
; remember information about connections, for developers' benefit?
EnabledP=1
; remember information about every database request?
DatabaseEnabledP=1
; remember information for which client hosts?
EnabledIPs=*
; remember this information for how long? sweep how often? (in seconds)
DataLifetime=900
DataSweepInterval=900</pre></blockquote>

Note that you may not want to enable this stuff for production systems - they probably
incur a slight performance hit (although this hasn't been benchmarked).

<h3>How It Works</h3>

The security subsystem registers preauth and trace filters which store relevant
connection information in shared variables (<tt>nsv</tt>s). The security subsystem
also renames the AOLserver <tt>ns_db</tt> procedure and registers a wrapper
which aggregates information about database queries.

<hr>
<%= [ad_call_proc_if_exists ds_link] %>
<address><a href="mailto:jsalz@mit.edu">jsalz@mit.edu</a></address>

</body>
</html>


