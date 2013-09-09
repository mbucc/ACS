<table>

<multiple name="shirts">

  <if %shirts.style% ne %Last.style%>

    <!-- Start a new row if the style changes -->

    <tr>
      <td>
        <var name="shirts.style">
      </td>
      <td>

  </if>

  <!-- List colors for the same style in a single cell -->

  <var name="shirts.color"><br>

  <if %shirts.style% ne %Next.style%>

    <!-- End the row if the style is going to change on the next row

      </td>
    </tr>

  </if>

</multiple>

</table>