<h1>Template Dictionary</h1>

<p><b>Title:</b> <var name="spec.title"></p>
<p><b>Comment:</b> <var name="spec.comment"></p>

<h3>Data Sources</h3>

<multiple name="spec.dict">

<if %spec.dict.structure% ne onevalue>
  <p><b>Name:</b> <var name="spec.dict.name"><br>
     <b>Structure:</b> <var name="spec.dict.structure"><br>
     <b>Comment:</b> <var name="spec.dict.comment">
  <blockquote>
</if>

<submultiple name="spec.dict.variables">

<p>
<b>Variable:</b> 
<tt>&lt;var name="<var name="spec.dict.variables.name">"&gt;</tt><br>
<b>Comment:</b> 
<var name="spec.dict.variables.comment">
</p>

</submultiple>

<if %spec.dict.structure% ne onevalue>
</blockquote>
</if>

</multiple>




