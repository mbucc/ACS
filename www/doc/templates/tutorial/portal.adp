<%
ad_page_contract {
	@author ?
	@creation-date ?
	@cvs-id portal.adp,v 1.1.1.1 2000/08/08 07:24:59 ron Exp
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
Page Components
</h2>

part of a tutorial on the <a href="index.adp">Dynamic Publishing System</a> 
by <a href="mailto:karlg@arsdigita.com">Karl Goldstein</a>

<hr>

<p>
One of the goals of template system is to enable publishers to
recycle page sections that need to appear consistently in various
places or contexts across a site.  The most common examples of
this would be headers, footers, and side bars that include 
standard fare such as navigation tools, a search box, ads and a
universal set of links to pages such as home, job opportunities, 
investor relations, etc.  The design of a "master template" that
includes these elements is the subject of a subsequent lesson.
</p>

<p>This lesson illustrates the use of subtemplates to build a simple
portal page.  The system consists of a top-level structural template
that defines the overall layout of the page, such as a two-column
table.  Distinct topic areas are self-contained in separate
subtemplates, each associated with its own dynamic data specification.
The topic areas can thus be easily be both reformatted and rearranged
on the page in accord with publisher or user preference.</p>

<h3>Create the specification file</h3>

<p>In this simple example the templates are static.  A true
portal would have a specification file for topic area to set up
the appropriate dynamic content to suit each user's preferences.</p>

<h3>Create the structural template</h3>

<p>The structural template for this lesson illustrates the use of the
<tt>include</tt> tag.  

<%=[ad_util_get_source "samples/portal.adp"]%> 

<p>The subtemplates are simply static HTML so they are not discussed here.</p>

<p><a href="samples/portal.adp">View results</a></p>

<a href="index">Tutorial Contents</a>

<hr>

<a href="mailto:karlg@arsdigita.com">karlg@arsdigita.com</a>













