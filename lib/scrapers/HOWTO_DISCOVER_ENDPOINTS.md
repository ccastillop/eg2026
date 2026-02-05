# Guía: Cómo Descubrir los Endpoints de la API del JNE

Esta guía te ayudará a descubrir los endpoints reales que usa la plataforma Voto Informado del JNE para obtener datos de candidatos a diputados.

## 🎯 Objetivo

Encontrar las URLs exactas que usa el sitio web `https://votoinformado.jne.gob.pe/diputados` para cargar los datos de candidatos cuando seleccionas diferentes distritos electorales.

## 🛠️ Herramientas Necesarias

- **Google Chrome** o **Firefox** (con DevTools)
- Conexión a Internet
- Papel y lápiz o un editor de texto para tomar notas

## 📋 Pasos Detallados

### Paso 1: Abrir Chrome DevTools

1. Abre **Google Chrome**
2. Visita: `https://votoinformado.jne.gob.pe/diputados`
3. Presiona **F12** (o Cmd+Option+I en Mac) para abrir DevTools
4. Ve a la pestaña **Network** (Red)

### Paso 2: Configurar Filtros

1. En la pestaña Network, busca el filtro de tipo de peticiones
2. Selecciona **XHR** o **Fetch** (esto filtra solo peticiones AJAX/API)
3. Marca la opción **Preserve log** (Preservar registro) para no perder las peticiones al navegar

### Paso 3: Limpiar y Observar

1. Haz clic en el botón **🚫 Clear** (Limpiar) en la parte superior izquierda del panel Network
2. Ahora, en la página web, selecciona un **distrito electoral** del dropdown
   - Por ejemplo: Lima, Arequipa, Cusco, etc.
3. Observa las peticiones HTTP que aparecen en el panel Network

### Paso 4: Identificar la Petición Correcta

Busca peticiones que:
- Retornen datos en formato **JSON**
- Tengan nombres relacionados con "candidatos", "diputados", "lista", etc.
- Se hagan después de seleccionar un distrito
- Tengan status code **200** (éxito)

**Pistas visuales:**
- Las peticiones JSON suelen tener el icono `{}` o contenido tipo `application/json`
- El tamaño del response suele ser significativo (varios KB)

### Paso 5: Inspeccionar la Petición

1. Haz clic en la petición que parece contener los datos
2. Ve a la pestaña **Headers** (Cabeceras):
   - Copia el **Request URL** completo
   - Anota el **Request Method** (GET, POST, etc.)
   - Revisa los **Query String Parameters** (parámetros de la URL)
   - Anota los **Request Headers** importantes (User-Agent, Authorization, etc.)

3. Ve a la pestaña **Preview** o **Response**:
   - Verifica que los datos sean los candidatos (nombres, DNI, partido, etc.)
   - Anota la estructura del JSON

### Paso 6: Probar con Múltiples Distritos

1. Limpia el panel Network de nuevo
2. Selecciona otro distrito diferente
3. Compara la nueva petición con la anterior
4. Identifica qué parámetros cambian (ej: distrito, código, ubigeo)

## 📝 Ejemplo de lo que Debes Anotar

```
REQUEST URL:
https://votoinformado.jne.gob.pe/api/candidatos/buscar

METHOD: 
POST

HEADERS:
Content-Type: application/json
User-Agent: Mozilla/5.0...
Referer: https://votoinformado.jne.gob.pe/diputados
Authorization: Bearer xxx (si existe)

QUERY PARAMETERS: (si es GET)
?distrito=LIMA&tipo=diputado&proceso=2026

REQUEST BODY: (si es POST)
{
  "idDistrito": "150000",
  "idTipoEleccion": 15,
  "idProceso": 124
}

RESPONSE STRUCTURE:
{
  "success": true,
  "data": [
    {
      "strNombres": "JUAN",
      "strApellidoPaterno": "PEREZ",
      "strDocumentoIdentidad": "12345678",
      ...
    }
  ]
}
```

## 🔍 URLs Comunes a Revisar

Basándome en patrones comunes del JNE, prueba estas URLs posibles:

```
https://votoinformado.jne.gob.pe/api/candidatos
https://votoinformado.jne.gob.pe/api/diputados
https://votoinformado.jne.gob.pe/api/busqueda
https://plataformaelectoral.jne.gob.pe/api/candidatos
```

## 🧪 Probar el Endpoint con curl

Una vez que encuentres el endpoint, pruébalo desde la terminal:

```bash
# Ejemplo con GET
curl -X GET "https://votoinformado.jne.gob.pe/api/candidatos?distrito=LIMA" \
  -H "User-Agent: Mozilla/5.0..." \
  -H "Accept: application/json"

# Ejemplo con POST
curl -X POST "https://votoinformado.jne.gob.pe/api/buscar" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"distrito":"LIMA","tipo":"diputado"}'
```

## 📊 Validar los Datos

Una vez que obtengas una respuesta JSON:

1. Verifica que incluya los campos necesarios:
   - Nombres y apellidos
   - DNI
   - Organización política
   - Cargo
   - Estado (inscrito, admitido, etc.)
   - Foto (GUID)
   - Ubicación (departamento, provincia)

2. Compara con los datos que ya tienes en `data/02_Diputados.json`

## 🎬 Alternativa: Usar el Modo "Copy as cURL"

1. En DevTools, haz clic derecho en la petición
2. Selecciona **Copy** → **Copy as cURL**
3. Pega en tu terminal para replicar la petición exacta
4. Esto te dará todos los headers y parámetros necesarios

## 📝 Actualizar el Scraper

Una vez que tengas toda la información, actualiza estos archivos:

1. `lib/scrapers/jne_deputies_scraper.rb`:
   - Actualiza `API_ENDPOINTS`
   - Actualiza `build_api_url` con los parámetros correctos
   - Actualiza `make_http_request` con los headers correctos
   - Actualiza `parse_response` con la estructura correcta del JSON

2. Ejemplo de actualización:

```ruby
API_ENDPOINTS = {
  candidates: '/api/candidatos/buscar'  # URL real que encontraste
}

def build_api_url(district)
  params = {
    idDistrito: district.ubigeo,        # Parámetro real
    idTipoEleccion: 15,                  # ID para diputados
    idProceso: 124                       # ID para EG 2026
  }
  # ...
end
```

## ⚠️ Consideraciones Importantes

1. **Rate Limiting**: No hagas demasiadas peticiones rápido
   - Agrega `sleep 1` entre peticiones
   - Respeta el servidor del JNE

2. **User-Agent**: Siempre incluye un User-Agent realista

3. **Legalidad**: 
   - Estos son datos públicos del JNE
   - Usar para fines informativos está permitido
   - No revendas los datos
   - Da crédito al JNE como fuente

4. **Cambios**: La estructura puede cambiar
   - Documenta todo
   - Mantén versiones del scraper

## 🆘 Si No Encuentras los Endpoints

**Opción A**: El sitio usa Server-Side Rendering
- Los datos se cargan con el HTML inicial
- Necesitarías un scraper de HTML con Nokogiri o Puppeteer

**Opción B**: El sitio usa JavaScript pesado
- Necesitarías Selenium o Playwright para ejecutar JS
- Más complejo pero factible

**Opción C**: Contactar al JNE
- Envía un correo pidiendo acceso a la API
- Explica que es para un proyecto cívico
- Email: mesadepartes@jne.gob.pe

## 📚 Recursos Adicionales

- [Chrome DevTools Network Reference](https://developer.chrome.com/docs/devtools/network/)
- [Postman](https://www.postman.com/) - Para probar APIs
- [HTTPie](https://httpie.io/) - Cliente HTTP amigable para terminal

## ✅ Checklist Final

Antes de implementar el scraper, verifica que tengas:

- [ ] URL completa del endpoint
- [ ] Método HTTP (GET/POST)
- [ ] Todos los parámetros necesarios
- [ ] Headers requeridos
- [ ] Estructura del JSON de respuesta
- [ ] Probado con curl/Postman
- [ ] Funciona con múltiples distritos
- [ ] Datos coinciden con el sitio web

---

**💡 Tip Final**: Si el sitio web carga los datos, tú también puedes obtenerlos. Solo necesitas paciencia para encontrar cómo. ¡Suerte!