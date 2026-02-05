# 🚀 GUÍA RÁPIDA: Obtener Datos de Diputados del JNE

## ✅ Pasos Completados

Ya se ha preparado toda la infraestructura necesaria:

- ✅ Tabla `electoral_districts` creada con 27 distritos
- ✅ Relación con tabla `candidates` establecida
- ✅ Scripts de scraping e importación listos
- ✅ Documentación completa disponible

## 🎯 Tu Siguiente Paso

**OPCIÓN 1: Descubrir el API del JNE** (RECOMENDADO para datos completos)

1. Abre Chrome y presiona F12
2. Lee `HOWTO_DISCOVER_ENDPOINTS.md` (guía paso a paso)
3. Visita: https://votoinformado.jne.gob.pe/diputados
4. Encuentra el endpoint que carga los datos
5. Actualiza `jne_deputies_scraper.rb` con la URL real
6. Ejecuta el scraper
7. Importa los datos

**OPCIÓN 2: Usar los datos parciales que ya tienes**

Los datos de Lima ya están cargados. Puedes:

```bash
# Ver qué datos tienes
rails runner 'puts "Diputados: #{Candidate.deputies.count}"; 
              puts "Lima: #{Candidate.deputies.where(department: \"LIMA\").count}"'
```

**OPCIÓN 3: Solicitar datos oficiales al JNE**

Envía un correo a: mesadepartes@jne.gob.pe

## 📚 Documentación

- `README.md` - Documentación completa del sistema
- `HOWTO_DISCOVER_ENDPOINTS.md` - Guía detallada para encontrar APIs
- `test_endpoint.rb` - Script para probar endpoints
- `jne_deputies_scraper.rb` - Scraper principal
- `import_scraped_deputies.rb` - Importador de datos

## 🧪 Prueba Rápida

```bash
# Probar el script de endpoints
ruby lib/scrapers/test_endpoint.rb

# Ver distritos electorales cargados
rails runner 'ElectoralDistrict.all.each { |d| puts d.display_name }'

# Ver estadísticas actuales
rails runner db/seeds/verify_data.rb
```

## ⏭️ ¿Qué Hacer Ahora?

1. Lee `HOWTO_DISCOVER_ENDPOINTS.md` **PRIMERO**
2. Abre Chrome DevTools
3. Encuentra el endpoint del JNE
4. Actualiza el scraper
5. ¡Obtén todos los datos!

**¿Necesitas ayuda?** Lee el README completo en este directorio.
