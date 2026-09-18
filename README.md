Haré un diagnóstico de solo lectura comparando la plantilla y la copia generada a nivel de párrafos, estilos, `runs`, tablas y estructura XML. La hipótesis inicial es que el generador escribe siempre en el párrafo inmediato posterior, aunque algunos rótulos de la jerarquía “Requisitos” usan párrafos de estilo `Heading 3` o no tienen un destino de contenido inequívoco.

Read 

Read 

Read 

Read 

Read 

El código confirma la causa probable: para cualquier sección, `_obtener_destinos()` selecciona `documento.paragraphs[indice + 1]` sin verificar estilo, saltos ni jerarquía visual. Ahora voy a extraer el mapa comparativo exacto de la plantilla y el resultado, incluyendo propiedades de párrafo y `runs`, para indicar qué destinos concretos son incorrectos.

Ran terminal command: $plantilla = Get-ChildItem -LiteralPath .\plantillas -Filter '*.docx' | Where-Object { $_.Name -notlike '.~lock*' } | Select-Object -First 1; $resultado = Get-Item -LiteralPath .\output\Prueba_especificaciones_tecnicas.docx; @'
from docx import Document
from pathlib import Path
import sys

for nombre, ruta in [('PLANTILLA', sys.argv[1]), ('RESULTADO', sys.argv[2])]:
    d = Document(ruta)
    print('\n===', nombre, '===')
    print('SECCIONES', len(d.sections), 'TABLAS', len(d.tables), 'PARRAFOS', len(d.paragraphs))
    for i, p in enumerate(d.paragraphs):
        pf = p.paragraph_format
        print(f'P{i:02d}|texto={p.text!r}|estilo={p.style.name!r}|alineacion={p.alignment}|antes={pf.space_before}|despues={pf.space_after}|interlineado={pf.line_spacing}|runs={[r.text for r in p.runs]}')
    for ti, tabla in enumerate(d.tables):
        print('TABLA', ti, 'filas', len(tabla.rows), 'columnas', len(tabla.columns))
        vistos = set()
        for ri, fila in enumerate(tabla.rows):
            for ci, celda in enumerate(fila.cells):
                if id(celda._tc) in vistos:
                    continue
                vistos.add(id(celda._tc))
                print(f'T{ti}R{ri}C{ci}|texto={celda.text!r}|parrafos={[(p.text, p.style.name, [r.text for r in p.runs]) for p in celda.paragraphs]}')
    for si, seccion in enumerate(d.sections):
        print('CABECERA', si, [p.text for p in seccion.header.paragraphs])
        print('PIE', si, [p.text for p in seccion.footer.paragraphs])
'@ | python - $plantilla.FullName $resultado.FullName

La comparación estructural se generó correctamente; leeré su salida para clasificar cada párrafo de sección, su destino seleccionado y el formato heredado que explica la superposición visual.

Read , lines 1 to 300

Read , lines 300 to 326

La comparación confirma que los valores de secciones no se mezclaron a nivel de XML: se insertaron en párrafos distintos. El defecto es de semántica y estilo: por ejemplo, `Requisitos del Producto:` se escribe en el párrafo 18 con estilo `Heading 3`, y su contenido queda visualmente como otro subtítulo justo antes de `Requisitos de Desempeño`; revisaré ahora las combinaciones reales de la tabla y los saltos/bloques XML para completar el diagnóstico de ubicación.

Ran terminal command: $plantilla = Get-ChildItem -LiteralPath .\plantillas -Filter '*.docx' | Where-Object { $_.Name -notlike '.~lock*' } | Select-Object -First 1; @'
from docx import Document
from pathlib import Path
from lxml import etree
import sys

ns={'w':'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}
d=Document(Path(sys.argv[1]))
t=d.tables[0]
print('TABLA')
for ri,row in enumerate(t.rows):
    print('FILA',ri,[(ci,id(c._tc),repr(c.text)) for ci,c in enumerate(row.cells)])
    for ci,c in enumerate(row.cells):
        tcpr=c._tc.tcPr
        grid=tcpr.gridSpan.val if tcpr is not None and tcpr.gridSpan is not None else None
        vm=tcpr.vMerge.val if tcpr is not None and tcpr.vMerge is not None else None
        print(' CELDA',ci,'gridSpan',grid,'vMerge',vm)
print('CUERPO')
for indice, elemento in enumerate(d.element.body.iterchildren()):
    etiqueta=etree.QName(elemento).localname
    if etiqueta=='p':
        texto=''.join(elemento.xpath('.//w:t/text()', namespaces=ns))
        saltos=len(elemento.xpath('.//w:br[@w:type="page"] | .//w:lastRenderedPageBreak', namespaces=ns))
        print(indice,'P',repr(texto),'salto_pagina',saltos)
    elif etiqueta=='tbl': print(indice,'TABLA')
    elif etiqueta=='sectPr': print(indice,'SECCION')
    else: print(indice,etiqueta)
'@ | python - $plantilla.FullName

La tabla no tiene combinaciones de celdas: sus seis filas presentan rótulo en columna 1 y destino vacío en columna 2. El intento de inspección de saltos XML falló por una incompatibilidad menor de la API XPath, pero no modificó archivos; lo repetiré directamente sobre `document.xml` para confirmar los saltos y la posición del bloque de firmas.

Ran terminal command: $plantilla = Get-ChildItem -LiteralPath .\plantillas -Filter '*.docx' | Where-Object { $_.Name -notlike '.~lock*' } | Select-Object -First 1; @'
from zipfile import ZipFile
from lxml import etree
import sys

ns={'w':'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}
with ZipFile(sys.argv[1]) as archivo:
    raiz=etree.fromstring(archivo.read('word/document.xml'))
    cuerpo=raiz.find('w:body', ns)
    for i, elemento in enumerate(cuerpo):
        tipo=etree.QName(elemento).localname
        if tipo == 'p':
            texto=''.join(elemento.xpath('.//w:t/text()', namespaces=ns))
            saltos_pagina=len(elemento.xpath('.//w:br[@w:type="page"]', namespaces=ns))
            salto_seccion=bool(elemento.xpath('./w:pPr/w:sectPr', namespaces=ns))
            print(i, 'P', repr(texto), 'salto_pagina', saltos_pagina, 'salto_seccion', salto_seccion)
        else:
            print(i, tipo)
'@ | python - $plantilla.FullName

**Diagnóstico**

La plantilla tiene 2 secciones Word, 1 tabla de 6 filas por 2 columnas y 55 párrafos de cuerpo. No contiene texto en encabezados ni pies. La copia generada conserva la misma cantidad de secciones, tabla y párrafos; el problema está en la selección del párrafo destino, no en la destrucción de la estructura XML.

| Campo | Ubicación y estructura | Comportamiento actual | Corrección propuesta |
|---|---|---|---|
| `Proyecto:` | Tabla 0, fila 0, columna 0; destino: columna 1 vacía | Correcto | Conservar: escribir en el primer párrafo de la segunda celda. |
| `Equipo de Evaluación del Proyecto:` | Tabla 0, fila 1, columna 0; destino: columna 1 vacía | Correcto | Igual. |
| `Ambiente:` | Tabla 0, fila 2, columna 0; destino: columna 1 vacía | Correcto | Igual. |
| `Tiempo Estimado:` | Tabla 0, fila 3, columna 0; destino: columna 1 vacía | Correcto | Igual. |
| `Indicador Impactado:` | Tabla 0, fila 4, columna 0; destino: columna 1 vacía | Correcto | Igual. |
| `Línea Base:` | Tabla 0, fila 5, columna 0; destino: columna 1 vacía | Correcto | Igual. |
| `Alcance:` | Párrafo 4; el siguiente, 5, está vacío y es `Normal` | Correcto estructuralmente | Escribir en párrafo 5. |
| `Características Claves de la Automatización:` | Párrafo 12; el siguiente, 13, está vacío y es `Normal` | Correcto estructuralmente | Escribir en párrafo 13. |
| `Requisitos del Producto:` | Párrafo 17, estilo `List Paragraph`; el siguiente, 18, está vacío pero es `Heading 3` | Incorrecto: el generador escribe el valor como encabezado y queda visualmente mezclado con `Requisitos de Desempeño` | No usar el siguiente párrafo por defecto. Este campo no tiene un destino de contenido inequívoco: registrar advertencia y no escribir, o definir con el usuario un destino explícito. |
| `Requisitos de Desempeño` | Párrafo 19, estilo `Heading 3`; párrafo 20 está vacío pero también es `Heading 3`; párrafo 21 vacío es `Normal` | Incorrecto: escribe en 20 con estilo de título | Seleccionar el primer párrafo vacío posterior de estilo de contenido (`Normal`), antes del siguiente título: párrafo 21. |
| `Riesgos` | Párrafo 22; párrafo 23 vacío `Normal` | Correcto | Escribir en 23. |
| `Garantía, Requisitos de Servicio` | Párrafo 25; párrafo 26 vacío `Normal` | Correcto | Escribir en 26. |
| `Buenas Prácticas Técnicas` | Párrafo 28; párrafo 29 vacío `Normal` | Correcto | Escribir en 29. |
| `Otros Requerimientos` | Párrafo 31; párrafo 32 vacío `Normal` | Correcto | Escribir en 32. |
| `Beneficiarios` | Párrafo 34; párrafo 35 vacío `Normal` | Correcto | Escribir en 35. |
| `Firmas:` | Párrafo 39; seguido por espacios, líneas de firma, cargos y dos rótulos `Nombre:` | No se completa porque no está en el conjunto de etiquetas; se conserva | Mantener excluido. No hay campos únicos ni destinos claros para los cuatro nombres/firma. |

El bloque de firmas empieza después de `Firmas:` y contiene líneas, cargos y rótulos duplicados `Nombre:`. Debe mantenerse intacto; no es un destino genérico de texto.

**Causa Técnica**

`generador_docx.py` asume que el destino de cualquier sección es `documento.paragraphs[indice + 1]`. Esa regla falla cuando el siguiente párrafo vacío es estructuralmente un título, como ocurre en los párrafos 18 y 20.

Además, añadir un `run` conserva el XML existente, pero hereda el estilo del párrafo elegido. Por eso los valores no se superponen en el XML, pero aparecen visualmente como encabezados o quedan demasiado próximos a otros títulos.

**Propuesta**

Cambiar la selección de destinos de párrafos para:

1. Mantener los destinos de tabla actuales.
2. Para cada etiqueta de sección, buscar hacia delante hasta el siguiente título conocido o `Firmas:`.
3. Elegir solo el primer párrafo vacío de contenido, excluyendo estilos `Heading 1` a `Heading 9` y `List Paragraph`.
4. Para `Requisitos del Producto:`, registrar advertencia y no escribir hasta definir un párrafo destino explícito.
5. Para `Requisitos de Desempeño`, usar el párrafo 21, no el 20.
6. Escribir mediante `parrafo.add_run(valor)` únicamente en el destino seleccionado.
7. No tocar tablas fuera de la segunda celda destino, títulos, firmas, encabezados, pies, saltos de sección ni los demás `runs`.

No realicé cambios. Espero tu confirmación para implementar esta corrección.
