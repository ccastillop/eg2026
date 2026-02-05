# 🚀 QUICKSTART: Obtener Todos los Diputados del JNE

¡El scraper está funcionando! Ya hemos confirmado que puede obtener datos del JNE.

## ✅ Estado Actual

- ✅ Endpoint del JNE descubierto y configurado
- ✅ Scraper probado con éxito (Lima: 136 candidatos)
- ✅ Sistema de importación listo
- ✅ Base de datos preparada con 27 distritos electorales

## 🎯 Obtener TODOS los Diputados (Método Rápido)

### Opción 1: Todo en Un Solo Comando (RECOMENDADO)

```bash
# Esto hace scraping de todos los distritos E importa a la base de datos
rails runner lib/scrapers/scrape_and_import.rb
```

Esto tomará aproximadamente **2-3 minutos** y:
1. ✅ Hace scraping de los 27 distritos electorales
2. ✅ Guarda el JSON completo en `tmp/`
3. ✅ Importa automáticamente a la base de datos
4. ✅ Muestra estadísticas completas

### Opción 2: Paso por Paso

```bash
# Paso 1: Scraping (genera JSON)
rails runner lib/scrapers/run_scraper.rb

# Paso 2: Importar el JSON generado
rails runner lib/scrapers/import_scraped_deputies.rb data/diputados_completo_TIMESTAMP.json
```

## 🧪 Probar con un Solo Distrito

```bash
# Probar con Lima (ya sabemos que funciona)
rails runner lib/scrapers/test_scraper.rb LIMA

# Probar con otro distrito
rails runner lib/scrapers/test_scraper.rb AREQUIPA
rails runner lib/scrapers/test_scraper.rb CUSCO
```

## 🎛️ Opciones Avanzadas

### Solo algunos distritos específicos

```bash
# Solo Lima y Arequipa
DISTRICTS=LIMA,AREQUIPA rails runner lib/scrapers/scrape_and_import.rb

# Solo distritos de la costa
DISTRICTS=LIMA,CALLAO,ICA,PIURA,LAMBAYEQUE rails runner lib/scrapers/scrape_and_import.rb
```

### Solo scraping (sin importar)

```bash
rails runner lib/scrapers/run_scraper.rb

# Con nombre personalizado
OUTPUT=mis_diputados.json rails runner lib/scrapers/run_scraper.rb
```

### Sin backup de base de datos

```bash
SKIP_BACKUP=true rails runner lib/scrapers/scrape_and_import.rb
```

## 📊 Ver Resultados

```bash
# Ver estadísticas actuales
rails runner <<-RUBY
  puts "Total Diputados: #{Candidate.deputies.count}"
  puts "\nPor Distrito Electoral:"
  Candidate.deputies
           .joins(:electoral_district)
           .group('electoral_districts.name')
           .count
           .sort_by { |_, count| -count }
           .each { |district, count| puts "  #{district}: #{count}" }
RUBY
```

## ⚠️ Notas Importantes

### El Token de Autenticación

El scraper usa este token del JNE:
```
AuthToken: 1454eebb-4b05-4400-93ac-25f0d0690d4b
UserId: 1381
```

**Si el scraper deja de funcionar:**
1. El token puede haber expirado
2. Necesitas obtener uno nuevo:
   - Abre Chrome DevTools (F12)
   - Ve a https://votoinformado.jne.gob.pe/diputados
   - Selecciona un distrito
   - En la pestaña Network, busca la petición a `ListaCandidatos`
   - Copia el nuevo `AuthToken` y `UserId`
   - Actualiza en `lib/scrapers/jne_deputies_scraper.rb` (líneas 13-14)

### Rate Limiting

El scraper espera **2 segundos** entre cada distrito para no sobrecargar el servidor del JNE.
- 27 distritos × 2 segundos = ~54 segundos mínimo
- Más el tiempo de procesamiento = 2-3 minutos total

## 🔧 Solución de Problemas

### "No se encontraron candidatos"

```bash
# Verifica que el distrito existe
rails runner "puts ElectoralDistrict.pluck(:code, :name)"

# Prueba con un distrito que sabemos funciona
rails runner lib/scrapers/test_scraper.rb LIMA
```

### "Error de conexión" o "Timeout"

```bash
# Verifica tu conexión a internet
curl https://sije.jne.gob.pe/ServiciosWeb/WSCandidato/ListaCandidatos

# Aumenta el timeout en jne_deputies_scraper.rb (línea 105)
# http.read_timeout = 60  # Aumentar de 45 a 60
```

### "JSON Parse Error"

Probablemente el token expiró. Sigue las instrucciones arriba para obtener uno nuevo.

### Ver logs detallados

```bash
# En desarrollo
rails runner lib/scrapers/scrape_and_import.rb 2>&1 | tee scraper_log.txt

# Esto guarda la salida en scraper_log.txt para revisarla después
```

## 📁 Archivos Generados

```
eg2026/
├── data/
│   └── diputados_completo_YYYYMMDD_HHMMSS.json  # Backup del scraping
├── tmp/
│   ├── scraped_deputies_YYYYMMDD_HHMMSS.json   # JSON temporal
│   └── backups/
│       └── database_before_import_*.sqlite3     # Backup de DB
```

## ✨ Comandos Útiles

```bash
# Verificar datos antes de scraping
rails runner db/seeds/verify_data.rb

# Limpiar diputados actuales (si quieres empezar de cero)
rails runner "Candidate.deputies.destroy_all"

# Ver organizaciones políticas
rails runner "PoliticalOrganization.all.each { |o| puts o.display_name }"

# Ver distritos electorales
rails runner "ElectoralDistrict.all.each { |d| puts d.display_name }"

# Contar candidatos sin distrito asignado
rails runner "puts Candidate.deputies.where(electoral_district_id: nil).count"
```

## 🎉 Después del Scraping

Una vez que tengas todos los datos:

1. **Verifica la completitud:**
   ```bash
   rails runner db/seeds/verify_data.rb
   ```

2. **Haz un backup final:**
   ```bash
   cp db/development.sqlite3 db/backups/complete_$(date +%Y%m%d).sqlite3
   ```

3. **Continúa con el desarrollo:**
   - Crear vistas para mostrar candidatos
   - Implementar búsqueda y filtros
   - Agregar comparación de candidatos
   - Publicar la aplicación

## 📞 ¿Necesitas Ayuda?

- Lee `README.md` para documentación completa
- Revisa `HOWTO_DISCOVER_ENDPOINTS.md` si necesitas actualizar el token
- Consulta los comentarios en el código de `jne_deputies_scraper.rb`

---

**¡A por los datos! 🇵🇪**