<%
ad_page_contract {
	@author ?
	@creation-date ?
	@cvs-id hello_world.adp,v 1.1.1.1 2000/08/08 07:24:59 ron Exp
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
A Simple Example
</h2>

part of a tutorial on the <a href="index.adp">Dynamic Publishing System</a> 
by <a href="mailto:karlg@arsdigita.com">Karl Goldstein</a>

<hr>

<p>This lesson should give you basic familiarity with writing
a template specification file and embedding dynamic content
in a related template.</p>

<h3>Create the specification file</h3>

<p>A specification file is a simple XML document that uses a standard
set of tags to describe the dynamic content presented by a
template.</p>

<p>Create a file named <tt>hello.data</tt> in a test directory of
your server and enter the following simple specification:</p>

<%=[ad_util_get_source "samples/hello.data"]%> 

<p>As this example shows, a template specification consists of some 
general properties followed by any number of data sources.  Data
sources may be query parameters, Tcl procedures, or database queries.
In this case, the data source returns a single string.  This is noted
in the metadata by assigned a value of <tt>onevalue</tt> to the
<tt>structure</tt> property.</p>

<h3>Create the template</h3>

<p>Once you have written the specification, you create a template that
references the dynamic content provided by this specification.  You
and other members of your team can review variable names and
descriptions in the online data dictionary generated from the
specification file.  The data dictionary is accessed from a web
browser via the URL of the specification file (the file must end
in the <tt>spec</tt> extension).  It is primarily intended as a
convenience to template authors.</p>

<p><a href="samples/hello.data">View the data dictionary</a></p>

<%=[ad_util_get_source "samples/hello.adp"]%> 

<p><a href="samples/hello.adp">View results</a></p>

<a href="index">Tutorial Contents</a>

<hr>

<a href="mailto:karlg@arsdigita.com">karlg@arsdigita.com</a>













