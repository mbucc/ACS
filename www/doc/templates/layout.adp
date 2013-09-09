<%
ad_page_contract {
	@author ?
	@creation-date ?
	@cvs-id layout.adp,v 1.1.1.1 2000/08/08 07:24:59 ron Exp
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
Page Layout
</h2>

using the <a href="index">Dynamic Publishing System</a> 
by <a href="mailto:karlg@arsdigita.com">Karl Goldstein</a>

<hr>
<div align=right><a href="spec">Previous</a> | 
<a href="forms">Next</a>  | 
<a href="index">Top</a></div>

<h3>Overview</h3>

<p>One of the challenges of managing a large, complex web site is to
maintain a consistent look and feel across multiple pages, while
retaining the ability to rapidly implement sitewide design changes as
necessary.  The publishing system addresses this issue with two mechanisms:
</p>

<ul>
<li><em>Component templates</em> encapsulating common page features.
<li><em>Master templates</em> defining the overall layout of a group
of pages.
<ul>

<h3>Component Templates</h3>


<h3>Master Templates</h3>

<p>Most large web sites define design guidelines for page layout,
specifying the position and format of common page sections such as
search boxes, navigation bars, ad banners and lists of common
hyperlinks.  The actual <em>content area</em>, displaying information
specific to the page, is typically somewhere in the center of all these
other sections.</p>

<p>The publishing system uses master templates to define the overall
layout of all page sections except the content area.

<div align=right><a href="spec">Previous</a> | 
<a href="forms">Next</a> | 
<a href="index">Top</a></div>

<hr>

<a href="mailto:karlg@arsdigita.com">karlg@arsdigita.com</a>
