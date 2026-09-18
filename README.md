Sí, implementa la arquitectura propuesta.

Quiero que implementes la integración completa XLSX + DOCX siguiendo
estas condiciones:

## 1. Orquestador

Crea:

src/orquestador_documentos.py

Debe coordinar:

1. lectura de etiquetas XLSX;
2. lectura de etiquetas DOCX;
3. unificación de etiquetas;
4. mapeo de una única descripción;
5. generación del XLSX;
6. generación del DOCX;
7. validación de los archivos generados;
8. reporte final de completados, faltantes y advertencias.

Debe reutilizar las funciones existentes y evitar duplicar lógica.

## 2. Mapeo

Modifica mapeo_campos.py únicamente si es necesario.

Agrega un parámetro opcional para permitir un modo no interactivo.

Por ejemplo:

solicitar_faltantes=True

El comportamiento actual debe mantenerse cuando sea True.

Cuando sea False:

- no utilizar input();
- no bloquear la ejecución;
- devolver None para campos que no tengan coincidencia;
- permitir que el orquestador reporte esos campos como faltantes.

Mantén compatibilidad con todas las pruebas existentes.

## 3. XLSX

Modifica generador_doc.py únicamente para que:

- los valores None no se escriban como valores completados;
- los campos faltantes puedan registrarse como advertencias;
- nunca se modifique la plantilla original;
- el resultado se guarde en output/.

No cambies innecesariamente la lógica que ya funciona.

## 4. DOCX

Reutiliza generador_docx.py tal como quedó corregido.

Debe conservar:

- formato;
- tablas;
- títulos;
- logos;
- encabezados;
- pies;
- saltos de página;
- firmas;
- estructura del documento.

No modifiques la plantilla original.

"Requisitos del Producto" debe continuar como pendiente/advertencia
mientras no exista un destino inequívoco.

## 5. Validador

Crea:

src/validador_documentos.py

Debe validar como mínimo:

- que los archivos generados existan;
- que puedan abrirse correctamente;
- que las plantillas originales sigan existiendo;
- que las plantillas originales no hayan sido modificadas;
- que los valores proporcionados se encuentren en los documentos
  generados cuando sea posible comprobarlo;
- que los campos faltantes y advertencias queden registrados.

Para comprobar que la plantilla no fue modificada, calcula el hash antes
y después de la generación.

No dependas únicamente de una comparación de fecha de modificación.

## 6. Orquestador

El orquestador debe producir:

output/Historia_de_usuario_generada.xlsx

output/Especificaciones_tecnicas_generadas.docx

y devolver un resultado estructurado que permita conocer:

- archivos generados;
- campos completados;
- campos faltantes;
- advertencias;
- resultado de validación.

## 7. Pruebas

Crea:

test/test_orquestador_documentos.py

Debe probar como mínimo:

- generación de XLSX y DOCX;
- descripción con información incompleta;
- reporte de campos faltantes;
- que no se utilice input() en modo no interactivo;
- que las plantillas originales no sean modificadas.

Crea:

test/test_validador_documentos.py

Debe probar:

- archivos existentes;
- archivos inválidos;
- comparación de hashes;
- detección de modificación de plantilla;
- reporte de advertencias.

Mantén todas las pruebas existentes.

## 8. Script de ejecución

No elimines probar_flujo.py.

Si consideras necesario crear un nuevo punto de entrada, crea:

generar_documentos.py

o un nombre equivalente y explica por qué.

## 9. Restricciones

NO modificar las plantillas dentro de:

plantillas/

NO inventar información.

NO eliminar contenido de las plantillas.

NO duplicar la lógica de lectura, mapeo o generación.

Mantén los nombres de funciones y variables en español siguiendo las
convenciones existentes.

## 10. Antes de finalizar

Ejecuta:

pytest -q

Si alguna prueba falla, corrige el problema y vuelve a ejecutar las
pruebas.

Después genera una ejecución real utilizando las plantillas del proyecto
y una descripción de prueba.

Al finalizar muéstrame:

1. archivos creados;
2. archivos modificados;
3. resumen de arquitectura;
4. resultado de pytest -q;
5. rutas de los dos documentos generados;
6. campos completados;
7. campos faltantes;
8. advertencias;
9. confirmación de que las plantillas originales no fueron modificadas..
