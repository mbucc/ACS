<html>

<head>
<title>
Dynamic Publishing System
</title>
</head>

<body>

<h2>
Tag Reference: <tt>INCLUDE</tt>
</h2>

part of the <a href="index.adp">Dynamic Publishing System</a> 
by <a href="mailto:karlg@arsdigita.com">Karl Goldstein</a>

<hr>
<div align=right><a href="if.adp">Previous</a> | 
<a href="multiple.adp">Next</a>  | 
<a href="../tags.adp">Top</a></div>

<h3>Summary</h3>

<p>The <tt>include</tt> tag is used to include a dynamic subtemplate
into the current template.  If the subtemplate is associated with its
own data file, the data sources will be evaluated prior to including
the subtemplate into the current template.</p>

<h3>Usage</h3>

<pre>&lt;include src="subtemplate.adp" attribute=value ...></pre>

<h3>Notes</h3>

<p><li>Variables specified by the data sources for the current
template are also accessible to nested templates.  In the event of
name conflicts, fully qualified variable names
(<tt>template.datasource.variable</tt>) may be used.</p>

<p><li>Arguments may be passed to the subtemplate by specifying
additional attributes to the <tt>include</tt> tag.  All attributes
except for <tt>src</tt> are assumed to be arguments and are set as
variables which the subtemplate may reference using the <tt>var</tt>
tag.  To pass a dynamic variable to the subtemplate, specify the
variable name as an attribute but do not give a value:

<pre>&lt;include src="subtemplate.adp" attribute ...></pre>

</p>

<p><li>If the <tt>src</tt> attribute begins with a slash, the path is
assumed to be relative to the pageroot of the server.  If not, the
path is assumed to be relative to the <em>current URL as requested by
the client</em>, NOT the URL of the current template.</p>

<p><li>If the page layout is sensitive to additional whitespace 
surrounding the subtemplate, then care must be taken that
the subtemplate does not contain any blank lines at the beginning or
end of the file.  

<div align=right><a href="if.adp">Previous</a> | 
<a href="multiple.adp">Next</a>  | 
<a href="../tags.adp">Top</a></div>

<hr>

<a href="mailto:karlg@arsdigita.com">karlg@arsdigita.com</a>





