<html>

<head>
<title>
Dynamic Publishing System
</title>
</head>

<body>

<h2>
Tag Reference: <tt>VAR</tt>
</h2>

part of the <a href="index.adp">Dynamic Publishing System</a> 
by <a href="mailto:karlg@arsdigita.com">Karl Goldstein</a>

<hr>
<div align=right><a href="multiple.adp">Previous</a> | 
<a href="../tags.adp">Top</a></div>

<h3>Summary</h3>

<p>The <tt>var</tt> tag is used to reference a variable set by
a template data source.</p>

<h3>Usage</h3>

<pre>
&lt;!-- onevalue data source -->
&lt;var name="variable">
&lt;var name="template.variable">

&lt;!-- onerow or multirow data sources -->
&lt;var name="datasource.variable">
&lt;var name="template.datasource.variable"></pre>

<h3>Notes</h3>

<p><li>Variables may referenced using a fully qualified name that
includes the name of the template, or a shorthand that omits the
name of the template.  The former is only necessary when the templates
used to construct a page have datasources and variables with the same
names.</p>

<div align=right><a href="multiple.adp">Previous</a> | 
<a href="../tags.adp">Top</a></div>

<hr>

<a href="mailto:karlg@arsdigita.com">karlg@arsdigita.com</a>





