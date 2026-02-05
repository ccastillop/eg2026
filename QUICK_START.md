# Quick Start Guide - Candidates UI

## Starting the Application

### Option 1: Using bin/dev (Recommended)

This starts both the Rails server and Tailwind CSS watcher:

```bash
bin/dev
```

### Option 2: Start Manually

If you prefer to run them separately (useful for debugging):

```bash
# Terminal 1: Rails server
rails server

# Terminal 2: Tailwind CSS watcher
rails tailwindcss:watch
```

## Accessing the Application

Once the server is running, open your browser and navigate to:

```
http://localhost:3000
```

You'll be automatically directed to the **Candidates Index** page (home page).

## Features Overview

### Candidates Index (Home Page)

**URL:** `http://localhost:3000/` or `http://localhost:3000/candidates`

**What you'll see:**
- Grid of 30 candidates per page (3 columns × 10 rows)
- Each card shows:
  - Candidate photo (or placeholder)
  - Full name
  - Position type (Presidente, Diputado, Senador, etc.)
  - Political party
  - Electoral district (if applicable)
  - Status badge

**How to use:**

1. **Browse:** Scroll through the grid and use pagination at the bottom
2. **Search:** Enter a name or DNI in the search box
3. **Filter by Position:** Select from dropdown (Presidente, Diputado, Senador, etc.)
4. **Filter by Party:** Select a political organization from dropdown
5. **Click on any card** to view full candidate details

### Candidate Details Page

**URL:** `http://localhost:3000/candidates/:id`

**What you'll see:**
- Large photo and header with candidate name
- Political organization details
- Personal information (DNI, gender, birth date, etc.)
- Electoral information (district, department, province)
- Additional data (electoral file code)

**Actions available:**
- **Back to list:** Returns to the index page
- **Print:** Opens browser print dialog for the page

## Example Queries

### Search Examples

1. Search by name:
   ```
   http://localhost:3000/candidates?search=Juan
   ```

2. Filter by Deputies:
   ```
   http://localhost:3000/candidates?position_type=DIPUTADO
   ```

3. Filter by Presidents:
   ```
   http://localhost:3000/candidates?position_type=PRESIDENTE%20DE%20LA%20REP%C3%9ABLICA
   ```

4. Combine search and filter:
   ```
   http://localhost:3000/candidates?search=Maria&position_type=DIPUTADO&page=2
   ```

## Database Statistics

Current data in the database:
- **Total Candidates:** 6,680
- **Political Organizations:** 46
- **Electoral Districts:** 27
- **Pages (30 per page):** 223

### Breakdown by Position:
- **Presidents:** 36
- **Vice Presidents:** 72
- **Deputies:** 5,297
- **Senators:** 1,275

## Responsive Design

The UI automatically adapts to different screen sizes:

- **Mobile** (< 768px): 1 column
- **Tablet** (768-1024px): 2 columns  
- **Desktop** (> 1024px): 3 columns

## Troubleshooting

### Styles not loading?

Make sure Tailwind CSS is running:
```bash
rails tailwindcss:build
```

Or use `bin/dev` which runs it automatically.

### No data showing?

Check if the database has been seeded:
```bash
rails runner "puts Candidate.count"
```

If it returns 0, run the seeds:
```bash
rails db:seed
```

### Server not starting?

Check if port 3000 is already in use:
```bash
lsof -ti:3000 | xargs kill -9  # macOS/Linux
```

Then start the server again.

## Next Steps

1. **Explore the data:** Browse through different pages and candidates
2. **Try filters:** Test different combinations of search and filters
3. **Check candidate details:** Click on various candidates to see their full information
4. **Test responsiveness:** Resize your browser window to see the responsive design

## Development Notes

- The index page is set as the root path (`/`)
- Pagination shows 30 candidates per page
- All filtering is done server-side for performance
- Images use fallback icons if photos are not available
- The UI is fully styled with Tailwind CSS v4

## Verification

To verify everything is set up correctly, run:

```bash
ruby script/verify_candidates_ui.rb
```

This will check:
- ✅ Models and data
- ✅ Routes configuration
- ✅ Controller methods
- ✅ Views existence
- ✅ Kaminari pagination
- ✅ Tailwind CSS setup
- ✅ Associations
- ✅ Filtering functionality

## Need Help?

Check the detailed documentation:
- `CANDIDATES_UI.md` - Complete feature documentation
- `README.md` - Project overview
- `SCRAPING_SUCCESS.md` - Data scraping information