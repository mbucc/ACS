<%
ad_page_contract {
	@author ?
	@creation-date ?
	@cvs-id master.adp,v 1.1.1.1 2000/08/08 07:24:59 ron Exp
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
Master Templates
</h2>

for the <a href="index">Dynamic Publishing System</a> 
by <a href="mailto:karlg@arsdigita.com">Karl Goldstein</a>

<hr>
<div align=right><a href="">Previous</a> | 
<a href="">Next</a>  | 
<a href="index">Top</a></div>

<h3>Overview</h3>

<p>Most web sites strive to maintain a consistent layout across all
pages.  A typical basic layout includes at minimum a standard header
and footer, and usually includes a sidebar as well.  The actual
content of each page is constrained to one area within the overall
design grid.</p>

<p>The dynamic publishing system allows you to create <em>master
templates</em> to specify the overall design grid of a page.  The
templates for individual pages need only specify the layout of the
content area.  When the system processes a page request, it generates
the HTML for the content area first.  It then outputs the master
template, embedding the code for the content area in the appropriate
place.</p>

