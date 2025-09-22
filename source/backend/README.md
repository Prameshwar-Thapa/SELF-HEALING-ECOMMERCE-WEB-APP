# E-commerce Backend API

Node.js/Express backend for the self-healing e-commerce application.

## Features

- 🚀 **Express.js** - Fast, unopinionated web framework
- 🗄️ **MySQL Integration** - RDS database connectivity
- 🔒 **Security** - Helmet, CORS, input validation
- 📊 **Health Checks** - Comprehensive health monitoring
- 🔄 **Auto-healing** - Graceful error handling
- 📦 **Compression** - Response compression for performance

## API Endpoints

### Health Check
```
GET /health
```
Returns server health status, uptime, and system metrics.

### Products
```
GET /api/products          # Get all products
GET /api/products/:id      # Get single product
GET /api/categories        # Get all categories
```

## Environment Variables

Copy `.env.example` to `.env` and configure:

```bash
# Database (from AWS Secrets Manager)
DB_HOST=your-rds-endpoint.amazonaws.com
DB_USER=ecommerceadmin
DB_PASSWORD=your-secure-password
DB_NAME=ecommerce_db

# Security
JWT_SECRET=your-jwt-secret
ALLOWED_ORIGINS=https://your-domain.com

# AWS
AWS_REGION=us-east-1
```

## Development

```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Start production server
npm start

# Package for deployment
npm run package
```

## Database Schema

### Categories Table
- `id` - Primary key
- `name` - Category name
- `description` - Category description
- `created_at` - Timestamp

### Products Table
- `id` - Primary key
- `name` - Product name
- `description` - Product description
- `price` - Product price (decimal)
- `category_id` - Foreign key to categories
- `image_url` - Product image URL
- `stock_quantity` - Available stock
- `is_active` - Active status
- `created_at` - Created timestamp
- `updated_at` - Updated timestamp

## Deployment

The application is packaged as `backend-deployment.zip` and deployed to EC2 instances via Terraform. The deployment process:

1. EC2 instances download the package from S3
2. Extract and install dependencies
3. Fetch configuration from AWS Secrets Manager
4. Start the application as a systemd service

## Architecture

- **Auto-scaling** - Runs on multiple EC2 instances
- **Load balancing** - Traffic distributed via ALB
- **Health monitoring** - ALB health checks on `/health`
- **Database** - Connects to RDS MySQL
- **Secrets** - Configuration from AWS Secrets Manager
- **Logging** - CloudWatch integration via systemd
