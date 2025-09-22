# E-commerce Frontend

React-based frontend for the self-healing e-commerce application.

## Features

- 🛒 Product catalog display
- 📱 Responsive design
- ⚡ Real-time API integration
- 🎨 Modern UI with CSS Grid
- 🔄 Error handling and loading states

## Development

```bash
# Install dependencies
npm install

# Start development server
npm start

# Build for production
npm run build
```

## API Integration

The frontend connects to the backend API at `/api/products` to fetch product data.

## Build Output

The `npm run build` command creates optimized production files in the `build/` directory, which are then uploaded to S3 via Terraform.

## Architecture

- **React 18** - Modern React with hooks
- **CSS Grid** - Responsive product layout
- **Fetch API** - HTTP requests to backend
- **Error Boundaries** - Graceful error handling
