<%
ad_page_contract {
	@author ?
	@creation-date ?
	@cvs-id history.adp,v 1.1.1.1 2000/08/08 07:24:59 ron Exp
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
History
</h2>

of the <a href="index">Dynamic Publishing System</a> 
by <a href="mailto:karlg@arsdigita.com">Karl Goldstein</a>

<hr>

<p>Updates to the <a
href="http://karl.arsdigita.com/projects/ad-template.tar">distribution
file</a> are noted here.</p>

<p>December 12, 1999 11:30 PM</p>

<blockquote>Core system is substantially complete, including caching
and validation of specification files, and a <tt>maxrows</tt> property
for multirow data sources.</blockquote>

<p>December 14, 1999 1:30 AM</p>

<blockquote>Fixed bug introduced by maxrows property.  Added separator
tag for within multiple blocks.  Implemented basic style control and
wrote tutorial lesson describing how it works.</blockquote>

<p>December 14, 1999 10:50 PM</p>

<blockquote>Progress on master template: I'm in the process of 
incorporating a site mapping module that I wrote previously.
I've dramatically improved the queries and need to incorporate
the admin pages.  This will be used to demonstrate dynamically
generated navigation bars as part of the master template.
</blockquote>

<p>December 15, 1999 11:00 PM</p>

<blockquote><p>Enhanced XML parser to handle attributes in addition
to content.  Used this to add a <tt>status</tt> option to datasource.
To specify a datasource as optional (this really only makes sense
for params, I think) you can now say:</p>

<tt>&lt;datasource status=optional&gt;</tt>

<p>This was a feature requested by a reviewer.  Also added a <tt>static</tt>
type of data source, useful for specifying test data or data that
simply doesn't change, such as menu items (assuming you have a very simple
logical structure to your site and don't want to use the site map module).</p>
</blockquote>

<p>December 16, 1999 11:00 AM</p>

<blockquote><p>Enhanced XML parser to retain order of a heterogeneous
collection of elements in a container.  This makes the parser better,
but more importantly is required to meet the spec for access control,
for which I'm writing a tutorial lesson now.  A related change
is that datasources (and now access control checks, as well as
non-output processing steps) are encapsulated in a <tt>process</tt>
container.  All the samples in the tutorial have been updated to
reflect this change.
</p>
</blockquote>

<p>December 16, 1999 11:45 PM</p>

<blockquote>Completed code for all types of static data sources.
Wrote master template to use for documentation pages as a general
example of how to write one.  Tutorial lesson explaining the 
template is forthcoming.
</blockquote>

<p>December 17, 1999 1:20 PM</p>

<blockquote>Finished code for site map module.  Admin pages
awaiting the forms manager.
</blockquote>

<p>December 20, 1999 2:45 PM</p>

<blockquote>Finished a draft spec for the forms manager.
</blockquote>

<p>December 25, 1999 9:41 PM</p>

<blockquote>Generalized the spec handling code for the form
specification files as well as anything else that might
ever come up.
</blockquote>

<p>December 26, 1999 7:45 PM</p>

<blockquote>Implemented basic form spec handler and form template
preparation code.
</blockquote>

<p>January 1, 2000 12:10 AM</p>

<blockquote>
Successful test of insert, update and delete forms.
</blockquote>

<p>January 3, 2000 11:30 PM</p>

<blockquote>
Initial integration of site map component.  Admin pages forthcoming.
</blockquote>

<p>January 5, 2000 10:35 PM</p>

<blockquote>
Several dozen small enhancements and bug fixes in response to the
people who are starting to use the system (gulp).
</blockquote>

<p>January 7, 2000 12:15 AM</p>

<blockquote>
Fixed a couple problems related to eval datasources for templates
and form options and added a between operator to the if tag.
</blockquote>

<p>January 10, 2000 12:15 AM</p>

<blockquote>
Admin pages for the site map module are almost ready.  A mechanism
for content indexing has been added to this module as well.  Several
other bug fixes here and there as well.
</blockquote>

<p>January 11, 2000 11:55 PM</p>

<blockquote> 
Added an ELSE tag to complement the IF tag.  Added
support for default value for optional param data sources (put
arbitrary Tcl code in the condition attribute).  The initial admin
pages for the site map module are done.  The data model installs and
uninstalls cleanly (for me at least).  The code for allocating values
to rows for inserts and updates in the form manager has been revamped
to better support multiple inserts from a single form.  One big
annoyance noted: the XML parser chokes if you have any angle brackets
in eval code.  I will probably have to require that you escape angles
as \< and \>.  
</blockquote>

<p>January 17, 2000 3:35 PM</p>

<blockquote> Enhanced the multiple tag to allow groupings when
variable values change.  Added support for the master template concept
and improved style processing.  Greatly expanded the database model
for the publishing system and added a raft of admin pages to support
content localization and management, indexing, and site map
management.  I now have a huge amount of additional documentation to
write.  If you need something in particular explained, please e-mail
me and I'll do that first.  </blockquote>

<p>January 18, 2000 12:30 AM</p>

<blockquote> Enhanced the IF tag to allow compound expressions using
the simplified syntax.  Enhanced the content manager to support
editing, preview and approval of content subsequent to initial 
approval.
</blockquote>

<p>January 21, 2000 1:00 PM</p>

<blockquote>Fixed XML parser to allow using < and > in evals or queries
(you need to escape them with a backslash when using them).  Updated
tag reference to reflect current functionality.  Numerous other
small fixes.
</blockquote>


<hr>

<a href="mailto:karlg@arsdigita.com">karlg@arsdigita.com</a>
