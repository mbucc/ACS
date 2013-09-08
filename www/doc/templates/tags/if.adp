<html>

<head>
<title>
Dynamic Publishing System
</title>
</head>

<body>

<h2>
Tag Reference: <tt>IF</tt>
</h2>

part of the <a href="index.adp">Dynamic Publishing System</a> 
by <a href="mailto:karlg@arsdigita.com">Karl Goldstein</a>

<hr>
<div align=right><a href="grid.adp">Previous</a> | 
<a href="include.adp">Next</a>  | 
<a href="../tags.adp">Top</a></div>

<h3>Summary</h3>

<p>The <tt>if</tt> tag is used to output a template section only when
certain conditions are met.</p>

<h3>Usage</h3>

<pre><%=[ad_util_get_source "usage/if.adp"]%></pre>

<h3>Notes</h3>

<p><li>Variables that are accessible via the <tt>var</tt> tag (and
global variables in general) can be referenced in <tt>if</tt>
statements by enclosing the variable name in percent signs, as
illustrated above.  Otherwise words are interpreted literally.

<p><li>Phrases with spaces in them must be enclosed in quotes to
be grouped correctly:
<pre>
  &lt;if %datasource.variable% eq "blue sky">
    &lt;td bgcolor=#0000ff>
  &lt;/if></pre>

<p><li>The <tt>else</tt> tag may be used following an <tt>if</tt> block
to specify an alternate template section when a condition is not true:
</p>

<pre>
  &lt;if %datasource.variable% eq "blue">
    &lt;td bgcolor=#0000ff>
  &lt;/if>
  &lt;else>
    &lt;td bgcolor=#ffffff>
  &lt;/else></pre>

<p><li>Compound statements can be created using the <tt>and</tt> and
<tt>or</tt> keywords, as illustrated above.  Any number of statements
may be connected in this fashion.  There is no way to group statements
to change the order of evaluation.</p>

<p><li>The a variable is tested using the <tt>nil</tt> operator, it will
return true if the variable is undefined or if the value of the
variable is an empty string.</p>

<div align=right><a href="grid.adp">Previous</a> | 
<a href="include.adp">Next</a>  | 
<a href="../tags.adp">Top</a></div>

<hr>

<a href="mailto:karlg@arsdigita.com">karlg@arsdigita.com</a>




