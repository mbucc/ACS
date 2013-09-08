<%
ad_page_contract {
	@author ?
	@creation-date ?
	@cvs-id install.adp,v 1.1.1.1 2000/08/08 07:24:59 ron Exp
}
%>

<html>
<head>
<title>
Dynamic Publishing System
</title>
</head>
<body>

<h2>
Installation
</h2>

part of the <a href="index">Dynamic Publishing System</a> 
by <a href="mailto:karlg@arsdigita.com">Karl Goldstein</a>

<hr>

<p><b>Note:</b>  The publishing system is still under initial
development.  All aspects are subject to change until the official
1.0 release.  The distribution is made available here for you to
try out, inspect the code and give feedback.  Caveat nerdor.</p>

<h3>New ACS installations</h3>

<p>This publishing system is distributed as part of ACS 3.3.x, and no
additional steps beyond the standard ACS installation procedure is
required.</p>

<h3>Existing ACS installation</h3>

<p>The publishing system has few dependencies on other ACS modules
(just the users table and user-group module) so it is easy to add to
existing ACS installations as well:</p>

<ol>

<li> <p>Obtain the <a
href="http://karl.arsdigita.com/projects/ad-template.tar">latest
distribution.</a> Updates to the distribution are recorded in the <a
href="history">Change History</a>.</p>

<li><p>Unpack the distribution in a temporary directory.  The distribution
contains a single top-level directory named <tt>template</tt>.</p>

<li><p>Copy (or symlink) the files in the <tt>tcl</tt> subdirectory to
the private Tcl library directory of your server.</p>

<li><p>Copy (or symlink) the <tt>templates</tt> directory to the page root 
of your server.</p>

<li><p>Copy (or symlink) the <tt>doc</tt> directory to
<tt>/doc/template</tt> in the page tree of your server.</p>

<li><p>Copy (or symlink) the <tt>admin</tt> directory to
<tt>/admin/template</tt> in the page tree of your server.</p>

<li><p><b>This step is optional.</b>  If you are planning on experimenting
with the site management, content management, or indexing tools built
on the core templating system, then you must load some data models 
by executing <tt>data-model-create.sql</tt> in the <tt>sql</tt>
directory of the distribution.  This will load them in the proper
order.</p>

</ol>

<h3>Configuration</h3>

<p>Be sure that ADP caching is turned <b>OFF</b> on your development server.
Otherwise buggy templates may linger in the cache and cause you frustration.
</p>

<hr>

<a href="mailto:karlg@arsdigita.com">karlg@arsdigita.com</a>






