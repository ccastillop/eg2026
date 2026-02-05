# Sistema de Scraping de Datos del JNE

Este directorio contiene las herramientas para obtener datos de candidatos a diputados desde la plataforma Voto Informado del JNE.

## 📁 Estructura de Archivos

```
lib/scrapers/
├── README.md                           # Este archivo
├── HOWTO_DISCOVER_ENDPOINTS.md        # Guía para descubrir APIs del JNE
├── jne_deputies_scraper.rb             # Scraper principal para diputados
├── test_endpoint.rb                    # Script de prueba de endpoints
└── import_scraped_deputies.rb          # Importador de datos scrapeados
```

## 🎯 Objetivo

Obtener datos completos de candidatos a diputados de todos los distritos electorales del Perú para las Elecciones Generales 2026.

## 📊 Estado Actual

- ✅ Datos de diputados de **Lima** ya disponibles (825 candidatos)
- ❌ Faltan datos de **26 distritos electorales** restantes
- ✅ Infraestructura de base de datos lista
- ✅ Sistema de importación implementado

## 🚀 Proceso Completo

### Fase 1: Descubrir los Endpoints del JNE

**Lo que necesitas hacer:**

1. Lee la guía completa: `HOWTO_DISCOVER_ENDPOINTS.md`
2. Abre Chrome DevTools y visita: https://votoinformado.jne.gob.pe/diputados
3. Inspecciona las peticiones de red cuando seleccionas diferentes distritos
4. Identifica el endpoint que devuelve los datos de candidatos
5. Anota:
   - URL completa
   - Método HTTP (GET/POST)
   - Parámetros necesarios
   - Headers requeridos
   - Estructura del JSON de respuesta

**Herramientas:**
- Chrome DevTools (F12 → Network tab)
- `lib/scrapers/test_endpoint.rb` para probar endpoints

### Fase 2: Configurar el Scraper

Una vez que descubras el endpoint correcto:

1. Edita `jne_deputies_scraper.rb`
2. Actualiza estas secciones:

```ruby
# Actualizar el endpoint real
API_ENDPOINTS = {
  candidates: '/api/ruta/real/que/encontraste'
}

# Actualizar los parámetros
def build_api_url(district)
  params = {
    # Parámetros reales que descubriste
    idDistrito: district.ubigeo,
    idTipoEleccion: 15,
    # ... etc
  }
end

# Actualizar parsing si es necesario
def parse_response(response_body)
  data = JSON.parse(response_body)
  # Ajustar según la estructura real
  data['data'] || data
end
```

### Fase 3: Ejecutar el Scraper

```bash
# Ejecutar el scraper completo
rails runner -e production <<-RUBY
  require './lib/scrapers/jne_deputies_scraper'
  scraper = Scrapers::JneDeputiesScraper.new
  scraper.scrape_all_deputies
  scraper.save_to_json('data/diputados_completo_$(date +%Y%m%d).json')
RUBY
```

O por distrito individual:

```ruby
# En rails console
require './lib/scrapers/jne_deputies_scraper'
scraper = Scrapers::JneDeputiesScraper.new

# Probar con un distrito
district = ElectoralDistrict.find_by(code: 'AREQUIPA')
scraper.scrape_district(district)
```

### Fase 4: Importar los Datos

```bash
# Importar el JSON scrapeado a la base de datos
rails runner lib/scrapers/import_scraped_deputies.rb data/diputados_completo_20260204.json
```

## 🧪 Pruebas y Desarrollo

### Probar Endpoints Manualmente

```bash
# Ejecutar el script de prueba
ruby lib/scrapers/test_endpoint.rb
```

Esto creará archivos en `tmp/` con las respuestas para que las analices.

### Probar con curl

```bash
# Ejemplo básico
curl -X GET "https://votoinformado.jne.gob.pe/api/candidatos?distrito=LIMA" \
  -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)" \
  -H "Accept: application/json"

# Guardar respuesta para análisis
curl -X GET "URL_AQUI" -H "Header: value" > tmp/response.json
```

### Verificar Datos Importados

```bash
# Ver estadísticas en la base de datos
rails runner <<-RUBY
  puts "Total diputados: #{Candidate.deputies.count}"
  
  puts "\nPor distrito electoral:"
  Candidate.deputies
           .joins(:electoral_district)
           .group('electoral_districts.name')
           .count
           .sort_by { |_, count| -count }
           .each { |district, count| puts "  #{district}: #{count}" }
  
  puts "\nSin distrito asignado: #{Candidate.deputies.where(electoral_district_id: nil).count}"
RUBY
```

## 📋 Checklist Completo

### Antes de Comenzar
- [ ] Ruby 3.x instalado
- [ ] Rails 8 funcionando
- [ ] Base de datos migrada (`rails db:migrate`)
- [ ] Distritos electorales cargados (`rails runner db/seeds/electoral_districts.rb`)

### Descubrimiento de API
- [ ] Chrome DevTools abierto
- [ ] Página visitada: https://votoinformado.jne.gob.pe/diputados
- [ ] Red monitoreada mientras se cambia de distrito
- [ ] Endpoint identificado
- [ ] Parámetros anotados
- [ ] Headers anotados
- [ ] Estructura JSON documentada
- [ ] Probado con curl/Postman

### Configuración de Scraper
- [ ] `API_ENDPOINTS` actualizado
- [ ] `build_api_url` ajustado
- [ ] `parse_response` ajustado
- [ ] Headers correctos configurados
- [ ] Probado con 1 distrito
- [ ] Funciona correctamente

### Scraping Masivo
- [ ] Scraper probado con 2-3 distritos diferentes
- [ ] Rate limiting configurado (delays entre requests)
- [ ] Manejo de errores verificado
- [ ] Timeout configurado
- [ ] Logs activados

### Importación
- [ ] JSON generado y guardado
- [ ] Estructura del JSON verificada
- [ ] Importador probado con datos de muestra
- [ ] Base de datos respaldada antes de importación masiva
- [ ] Importación ejecutada
- [ ] Datos verificados en la base de datos

## ⚠️ Consideraciones Importantes

### Legal y Ético

1. **Datos Públicos**: Los datos del JNE son públicos y de acceso libre
2. **Uso Responsable**: Solo para fines informativos y educativos
3. **Atribución**: Siempre dar crédito al JNE como fuente oficial
4. **No Comercial**: No revender estos datos

### Técnico

1. **Rate Limiting**: 
   - Agrega `sleep 1` o `sleep 2` entre peticiones
   - No sobrecargues el servidor del JNE
   - Ejecuta durante horarios de baja demanda

2. **Monitoreo**:
   - Revisa logs constantemente
   - Verifica que los datos sean correctos
   - Compara con el sitio web del JNE

3. **Errores Comunes**:
   - 403 Forbidden → Falta User-Agent o está bloqueado
   - 429 Too Many Requests → Demasiadas peticiones rápido
   - 500 Server Error → Servidor del JNE caído o parámetros incorrectos
   - Timeout → Aumenta el timeout o reintenta

4. **Backup**:
   - Guarda copias de los JSON scrapeados
   - Respalda la base de datos antes de importaciones masivas

## 🔄 Flujo de Trabajo Recomendado

### Día 1: Reconocimiento
1. Leer toda la documentación
2. Explorar la web del JNE con DevTools
3. Identificar endpoints
4. Documentar estructura de datos

### Día 2: Pruebas
1. Probar endpoints con curl/test_endpoint.rb
2. Ajustar el scraper
3. Probar con 1-2 distritos
4. Verificar calidad de datos

### Día 3: Scraping
1. Respaldar base de datos
2. Ejecutar scraper para todos los distritos
3. Monitorear progreso
4. Guardar resultados

### Día 4: Importación
1. Verificar JSONs generados
2. Importar a base de datos
3. Verificar integridad
4. Documentar proceso

## 📚 Recursos Adicionales

### Documentación JNE
- [Plataforma Electoral](https://plataformaelectoral.jne.gob.pe/)
- [Voto Informado](https://votoinformado.jne.gob.pe/)
- [Infogob](https://infogob.jne.gob.pe/)

### Herramientas
- [Chrome DevTools](https://developer.chrome.com/docs/devtools/)
- [Postman](https://www.postman.com/)
- [HTTPie](https://httpie.io/)
- [jq](https://stedolan.github.io/jq/) - Procesador JSON para terminal

### Ruby Gems Útiles
- `nokogiri` - Para scraping HTML si es necesario
- `selenium-webdriver` - Para sitios con mucho JavaScript
- `httparty` - Cliente HTTP más simple

## 🆘 Solución de Problemas

### "No encuentro el endpoint"

**Solución**: El sitio puede usar Server-Side Rendering o JavaScript pesado.

Alternativas:
1. Usa Selenium/Playwright para ejecutar JavaScript
2. Scraping de HTML con Nokogiri
3. Contacta al JNE para solicitar acceso a API

### "403 Forbidden"

**Solución**: Servidor rechaza tu petición.

Intentos:
1. Agrega User-Agent realista
2. Agrega más headers (Referer, Accept, etc.)
3. Usa cookies de una sesión válida
4. Considera usar proxy

### "Datos incorrectos o incompletos"

**Solución**: Parsing incorrecto de la respuesta.

Pasos:
1. Guarda respuesta raw en archivo
2. Analiza estructura JSON cuidadosamente
3. Ajusta método `parse_response`
4. Compara con datos en el sitio web

### "Muy lento"

**Solución**: Optimización necesaria.

Opciones:
1. Paralelización (con cuidado, respeta rate limits)
2. Cachear organizaciones políticas
3. Usar transacciones de base de datos
4. Optimizar queries

## 📞 Contacto y Soporte

Si necesitas ayuda o tienes datos para compartir:

- **JNE Mesa de Partes**: mesadepartes@jne.gob.pe
- **JNE Consultas**: (01) 311-1700
- **Plataforma Electoral**: Formulario de contacto en el sitio

## 📝 Notas de Desarrollo

### Formato del JSON de Salida

El scraper genera JSON en este formato:

```json
{
  "metadata": {
    "scraped_at": "2026-02-04T10:30:00-05:00",
    "total_districts": 27,
    "total_candidates": 2500,
    "errors": 0
  },
  "districts": [
    {
      "district_code": "AREQUIPA",
      "district_name": "Arequipa",
      "candidates_count": 70,
      "candidates": [
        {
          "strNombres": "JUAN",
          "strApellidoPaterno": "PEREZ",
          "strApellidoMaterno": "LOPEZ",
          "strDocumentoIdentidad": "12345678",
          ...
        }
      ]
    }
  ],
  "errors": []
}
```

### Mapeo de Campos

| Campo JSON | Campo DB | Tipo | Notas |
|------------|----------|------|-------|
| strNombres | first_name | string | Nombre(s) |
| strApellidoPaterno | paternal_surname | string | Apellido paterno |
| strApellidoMaterno | maternal_surname | string | Apellido materno |
| strDocumentoIdentidad | document_number | string | DNI |
| strCargo | position_type | string | Siempre "DIPUTADO" |
| intPosicion | position_number | integer | Posición en lista |
| strEstadoCandidato | status | string | INSCRITO, ADMITIDO, etc. |
| idOrganizacionPolitica | political_organization_id | FK | Código de partido |

## 🎉 Próximos Pasos

Una vez que tengas todos los datos:

1. ✅ Verificar completitud (todos los distritos)
2. ✅ Verificar calidad (nombres, DNI, etc.)
3. 🚀 Crear vistas en la aplicación web
4. 🔍 Implementar búsqueda y filtros
5. 📊 Generar estadísticas
6. 🌐 Publicar la aplicación

---

**💡 Recuerda**: La paciencia es clave. El scraping puede tomar tiempo, pero al final tendrás datos valiosos para ayudar a los ciudadanos a votar informadamente.

¡Buena suerte! 🇵🇪