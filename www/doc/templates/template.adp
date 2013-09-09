<%
ad_page_contract {
	@author ?
	@creation-date ?
	@cvs-id template.adp,v 1.1.1.1 2000/08/08 07:24:59 ron Exp
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
Template Management
</h2>

for the <a href="index">Dynamic Publishing System</a> 
by <a href="mailto:karlg@arsdigita.com">Karl Goldstein</a>

<hr>

<h3>Overview</h3>

<p>Active web publishers constantly update the look and feel of their
pages to keep their site looking fresh and encourage repeat visits by
their users.  To do this efficiently they need an efficient mechanism
for organizing and editing page templates on their development site,
and "pushing" approved content to the production site.  This document
describes how this may be accomplished within the context of this
publishing system.</p>

<p>Templates are stored as text files on the server.  Historically
publishers have edited templates by using FTP to download them to a
local computer.  After making changes in a text editor, they would
upload them to the development server to preview the effects of the
changes.  The revised template would then be "pushed" by transferring
the file to the production server.</p>

<p>This system works well when a single person is both responsible for
changes to the templates and has the requisite access to both the
development and production servers to implement changes.  When
multiple people are working on the site simultaneously, it is not
ideal because people can overwrite each other's work without any way
to recover the overwritten changes.  The operation of an FTP server on
a production server is also widely considered to be a security risk
(see <a href="http://www.amazon.com/exec/obidos/ASIN/1565922697">Web
Security & Commerce</a> for an excellent review of web security).</p>

<p>The other problem with the simple traditional approach is that the
publisher has no integrated means to organize templates for easy
browsing and review by all people working on the site.</p>

<p>The template management component of the publishing system aims to
provide a single convenient, browser-based interface for transferring,
organizing, editing and "pushing" template additions and changes.</p>

<h3>Organization</h3>

<p>The template manager can take advantage of the site manager to
organize templates in a logical fashion.  Single- or narrow-purpose
templates may be associated with specific nodes of the visible site
tree, via an "add template" function similar to the "add page"
function.  Note that templates are distinct from pages because they
typicaly represent page components that are included in one or more
pages, rather than the complete layout of a unique page.  In some
cases publishers may also want to create a separate root node in the
site map for organizing certain kinds of templates.</p>

<p>The list of templates associated with a node should like to an
administrative page for a single template, with access the functionality
described in the remainder of this document.</p>

<p><em>At the very least, it seems desirable to have a list of templates
and descriptions in the database (i.e. they must be 'registered' with
the system to access them).</em></p>

<h3>Transfer</h3>

<p>Designers and template authors need a way to transfer templates
and related resources (primarily images) back and forth between the
server and their local computers.  FTP is convenient, but is not
appropriate for a secure collaborative environment.</p>

<p>The alternative is a file upload form that is integrated with the
template manager.  This is secure and can be tied into a revision
control system for transparently maintaining a history of changes
to the template.  The approach is cumbersome for template authors, however,
if upload is limited to a single file at a time.  Preferable would be
the ability to upload a zip file with multiple files.</p>

<h3>Editing</h3>

<p>For simple changes, editing a template in a large text area within
the browser is sufficient.  Submissions via this route should also be
integrated with revision control.

<h3>Pushing</h3>

<p>This represents the most complicated aspect of template management.
Site managers need a way to securely transfer approved template
updates and associated resources from development to production servers.
Here is one way this could happen:

<ul>
  <li>The publisher views a master list of templates and selects
      one or more for pushing.
  <li>The system scans the selected templates for associated resources 
      (images, etc.) that may need to be updated as well.
  <li>The list of all files is shown to the publisher for approval.
      At this point individual files or complete directories of files
      may be added to the push list (the latter most commonly containing
      dynamically inserted images that are not directly referenced in the
      template.
  <li>The list of files is transferred to the production server by HTTP
      operations (<em>Do an httpget to /admin/push.tcl?url=...</em> or 
      something to add a file to the list</em>)
  <li>The publisher than moves to an admin page on the production server,
      showing the list of files to transfer.  The list may be approved
      and files are then copied (resources first, then templates) to their 
      appropriate locations on the production server.
  <li>Previous versions of the live files must be archived somehow so
      that it is possible to revert back if there's a problem.
</ul>
      

<hr>

<a href="mailto:karlg@arsdigita.com">karlg@arsdigita.com</a>
