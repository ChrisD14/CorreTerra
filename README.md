La versión v2 del DOCX mantiene correctamente la estructura de la
plantilla y los valores aparecen debajo de sus respectivos títulos.

Ahora quiero hacer una prueba más realista del generador.

Utiliza una descripción de automatización más completa y genera:

output/Prueba_especificaciones_tecnicas_v3.docx

Usa esta información:

Proyecto: Automatización de generación de documentación
Equipo de Evaluación del Proyecto: Equipo de automatización documental
Ambiente: Desarrollo
Tiempo Estimado: 4 semanas
Indicador Impactado: Tiempo de elaboración de documentación
Línea Base: Elaboración manual de documentos con revisión por parte del equipo

Alcance: Automatizar la generación de la Historia de Usuario y las
Especificaciones Técnicas a partir de información proporcionada por
el responsable de la automatización.

Características Claves de la Automatización: La solución debe identificar
los campos requeridos, mapear la información proporcionada y generar
automáticamente los documentos utilizando las plantillas oficiales.

Requisitos de Desempeño: Generar los documentos de forma consistente y
reducir el tiempo necesario para completar manualmente las plantillas.

Riesgos: Información incompleta o ambigua proporcionada por el usuario,
cambios futuros en las plantillas y errores en el mapeo de campos.

Garantía, Requisitos de Servicio: La solución debe validar los documentos
generados y reportar los campos que no pudieron completarse.

Buenas Prácticas Técnicas: Utilizar Python, pruebas unitarias, manejo
explícito de errores y conservar las plantillas originales sin
modificarlas.

Otros Requerimientos: Los documentos generados deben almacenarse en
la carpeta output.

Beneficiarios: Equipo responsable del desarrollo y documentación de
automatizaciones.

IMPORTANTE:
- No modifiques ninguna plantilla.
- No inventes información adicional.
- Mantén el formato original.
- Ejecuta las pruebas después de generar el documento.
- Indica qué campos fueron completados y cuáles no.