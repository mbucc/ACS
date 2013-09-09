<%
ad_page_contract {
	@author ?
	@creation-date ?
	@cvs-id emacs.adp,v 1.1.1.1 2000/08/08 07:24:59 ron Exp
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
Macros for Editing Data Specifications
</h2>

of the <a href="index">Dynamic Publishing System</a> 
by <a href="mailto:karlg@arsdigita.com">Karl Goldstein</a>

<hr>

<p>The template system includes a set of simple macros that
simplify the task of writing data specification files in Emacs.
The macros are defined in a file named <tt>template.el</tt>
in the root directory of the template distribution.</p>

<p>To manually load the macros, type <b>ESC x load-file RETURN</b>,
followed by the path to the macro file.  The <tt>load-file</tt>
command can also be placed in your <tt>.emacs</tt> file to load
the macros every time you start Emacs.</p>

<p>The macros all work in a similar fashion.  Typing one of the
commands begins an XML element of type <tt>template</tt>,
<tt>datasource</tt> or <tt>variable</tt>.  The macro pauses whenever
your input is required.  To resume the macro, type <b>ESC C-c</b>.</p>

<p>For forms, there are a series of admin pages
under <tt>/admin/template</tt> to guide you through the process of
creating a form specification from scratch.  A similar
set of pages is planned for data specifications.</p>

<table border=1 cellpadding=2 cellspacing=0>
<tr bgcolor=#dddddd>
<th>Keyboard Shortcut</th><th>Description</th>
</tr>
<tr>
<th>C-x t s</th><td>Creates a new template specification file</td>
</tr>
<tr>
<th>C-x t p</th><td>Creates a new datasource of type <tt>param</tt></td>
</tr>
<tr>
<th>C-x t e</th><td>Creates a new datasource of type <tt>eval</tt></td>
</tr>
<tr>
<th>C-x t m</th><td>Creates a new datasource of type <tt>query</tt>
and structure <tt>multirow</tt>.</td>
</tr>
<tr>
<th>C-x t r</th><td>Creates a new datasource of type <tt>query</tt>
and structure <tt>onerow</tt>.</td>
</tr>
<tr>
<th>C-x t o</th><td>Creates a new datasource of type <tt>query</tt>
and structure <tt>onevalue</tt>.</td>
</tr>
<tr>
<th>C-x t v</th><td>Creates a new variable.</td>
</tr>
</table>

<hr>

<a href="mailto:karlg@arsdigita.com">karlg@arsdigita.com</a>
