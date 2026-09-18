Implementa ahora la generación automática de la plantilla DOCX.

Objetivo:

A partir de un diccionario de valores ya obtenido por mapeo_campos.py,
crear una copia de:

plantillas/3. Especificaciones técnicas V....docx

y completar únicamente los campos correspondientes.

Requisitos:

1. Utilizar python-docx.
2. Nunca modificar la plantilla original.
3. Crear el resultado dentro de output/.
4. Mantener el formato original.
5. Mantener tablas.
6. Mantener encabezados y pies de página.
7. Mantener las secciones de firmas.
8. Buscar los campos tanto en tablas como en párrafos.
9. No modificar títulos que no sean campos.
10. No eliminar contenido de la plantilla.
11. Si un campo no puede localizarse claramente, registrar una advertencia.
12. No inventar valores.
13. Separar la lógica de lectura, mapeo y generación.
14. Agregar manejo de errores.
15. Crear pruebas unitarias para la lógica nueva.

Antes de modificar archivos, explica qué archivos vas a cambiar.