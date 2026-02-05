# Candidates UI Documentation

## Overview

This document describes the Candidates Index and Show pages that have been implemented for the EG2026 political database management system.

## Features Implemented

### 1. Candidates Index Page (Home Page)

**Route:** `/` (root) and `/candidates`

**Features:**
- **Grid Layout**: 3-column responsive grid that displays 30 candidates per page (10 rows × 3 columns)
- **Pagination**: Implemented using Kaminari gem with custom Tailwind CSS styling
- **Responsive Design**: Adapts to mobile, tablet, and desktop screens
- **Search & Filters**:
  - Text search by name or DNI (document number)
  - Filter by position type (Presidente, Vicepresidente, Diputado, Senador)
  - Filter by political organization
  - Clear filters option

**Each Candidate Card Displays:**
- Photo (with fallback to default avatar icon)
- Full name
- Position type (cargo)
- Political party/organization acronym
- Electoral district (if applicable)
- Position number in the list
- Status badge (color-coded: green for INSCRITO/ADMITIDO, gray for others)

**Styling:**
- Clean, modern design using Tailwind CSS
- Hover effects on cards
- Shadow and border styling for visual hierarchy
- Responsive text sizing

### 2. Candidates Show Page

**Route:** `/candidates/:id`

**Features:**
- **Header Section**: 
  - Large candidate photo
  - Full name
  - Position type
  - Status badge
  - Position number
  - Gradient blue background for visual impact

- **Information Sections**:
  1. **Political Organization**
     - Organization name and acronym
     - Organization type and status
  
  2. **Personal Information**
     - Document type and number
     - Gender
     - Birth date
     - Native status
  
  3. **Electoral Information**
     - Electoral district with seat count
     - Department, Province, District
  
  4. **Additional Information**
     - Electoral file code

- **Actions**:
  - Back to list button
  - Print button (opens browser print dialog)

**Styling:**
- Card-based layout with sections
- Icon usage for visual clarity
- Color-coded sections
- Responsive grid for information display

## Technical Implementation

### Dependencies

- **Kaminari** (v1.2.2): Pagination gem
- **Tailwind CSS Rails** (v4.4.0): CSS framework

### Files Created/Modified

1. **Controller**: `app/controllers/candidates_controller.rb`
   - `index` action with filtering and pagination
   - `show` action with eager loading

2. **Views**:
   - `app/views/candidates/index.html.erb`
   - `app/views/candidates/show.html.erb`

3. **Kaminari Views** (Tailwind CSS customization):
   - `app/views/kaminari/_paginator.html.erb`
   - `app/views/kaminari/_page.html.erb`
   - `app/views/kaminari/_gap.html.erb`
   - `app/views/kaminari/_first_page.html.erb`
   - `app/views/kaminari/_last_page.html.erb`
   - `app/views/kaminari/_next_page.html.erb`
   - `app/views/kaminari/_prev_page.html.erb`

4. **Routes**: `config/routes.rb`
   - Added `resources :candidates, only: [:index, :show]`
   - Set `root "candidates#index"`

5. **Layout**: `app/views/layouts/application.html.erb`
   - Removed container wrapper to allow full-page layouts

### Database Queries

The index and show actions use optimized queries with eager loading:

```ruby
# Index
@candidates = Candidate.includes(:political_organization, :electoral_district)
                       .order(:paternal_surname, :maternal_surname, :first_name)
                       .page(params[:page])
                       .per(30)

# Show
@candidate = Candidate.includes(:political_organization, :electoral_district)
                     .find(params[:id])
```

## Running the Application

### Development Server

Start the application using foreman (handles both Rails server and Tailwind CSS compilation):

```bash
bin/dev
```

Or start them separately:

```bash
# Terminal 1: Rails server
rails server

# Terminal 2: Tailwind CSS watcher
rails tailwindcss:watch
```

### Accessing the Application

- **Home/Index**: http://localhost:3000
- **Candidate Details**: http://localhost:3000/candidates/:id

## Filter Parameters

The index page accepts the following query parameters:

- `page`: Page number (default: 1)
- `search`: Search term for name or DNI
- `position_type`: Filter by position (e.g., "DIPUTADO", "PRESIDENTE DE LA REPÚBLICA")
- `political_organization_id`: Filter by political organization ID
- `electoral_district_id`: Filter by electoral district ID

**Example URLs:**
- `/candidates?search=Juan`
- `/candidates?position_type=DIPUTADO&page=2`
- `/candidates?political_organization_id=5`

## Pagination Configuration

- **Items per page**: 30 candidates
- **Grid layout**: 3 columns × 10 rows
- **Navigation**: Previous, Next, First, Last buttons plus page numbers
- **Styling**: Custom Tailwind CSS theme matching the application design

## Responsive Breakpoints

- **Mobile** (< 768px): 1 column
- **Tablet** (768px - 1024px): 2 columns
- **Desktop** (> 1024px): 3 columns

## Future Enhancements

Potential improvements for future iterations:

1. **Advanced Filters**:
   - Filter by electoral district
   - Filter by gender
   - Filter by age range
   - Multi-select filters

2. **Sorting Options**:
   - Sort by name, party, district, position

3. **Comparison Feature**:
   - Select multiple candidates to compare side-by-side

4. **Export Functionality**:
   - Export filtered results to CSV/PDF

5. **Photo Integration**:
   - Integrate with JNE photo API if available
   - Implement photo upload for missing photos

6. **Analytics Dashboard**:
   - Statistics by party, district, gender
   - Visual charts and graphs

7. **Search Improvements**:
   - Full-text search with PostgreSQL
   - Fuzzy matching for names

## Notes

- The current implementation displays 6,680 candidates across 223 pages
- Photos use a fallback SVG icon if not available
- The application uses SQLite in development (46 political organizations, 27 electoral districts)
- All styling is done with Tailwind CSS v4.1.18