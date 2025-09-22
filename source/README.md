# Source Code

This directory contains the source code for the self-healing e-commerce application.

## 📁 Structure

```
source/
├── frontend/          # React frontend application
│   ├── src/          # React components and logic
│   ├── public/       # Static assets
│   └── package.json  # Dependencies and scripts
├── backend/          # Node.js API server
│   ├── server.js     # Main application file
│   ├── package.json  # Dependencies and scripts
│   └── .env.example  # Environment configuration template
└── README.md         # This file
```

## 🚀 Quick Start

### Frontend Development
```bash
cd frontend
npm install
npm start
# Opens http://localhost:3000
```

### Backend Development
```bash
cd backend
npm install
cp .env.example .env
# Edit .env with your database credentials
npm run dev
# API available at http://localhost:3000
```

## 🏗️ Build Process

### Frontend Build
```bash
cd frontend
npm run build
# Creates optimized build in build/ directory
# Copy contents to project root build/ folder
```

### Backend Package
```bash
cd backend
npm run package
# Creates backend-deployment.zip in parent directory
```

## 🔄 Integration with Terraform

The source code is built and packaged separately from the Terraform deployment:

1. **Frontend**: Built React app goes to `build/` directory
2. **Backend**: Packaged Node.js app becomes `backend-deployment.zip`
3. **Terraform**: Uploads both to S3 and deploys infrastructure

## 🎯 Features

### Frontend (React)
- ✅ Modern React 18 with hooks
- ✅ Responsive CSS Grid layout
- ✅ API integration with error handling
- ✅ Loading states and user feedback
- ✅ Product catalog display

### Backend (Node.js)
- ✅ Express.js REST API
- ✅ MySQL database integration
- ✅ Health check endpoints
- ✅ Security middleware (Helmet, CORS)
- ✅ Environment-based configuration
- ✅ Graceful shutdown handling

## 🔧 Development vs Production

### Development
- Hot reloading for frontend
- Nodemon for backend auto-restart
- Local database or development RDS
- Detailed error messages

### Production
- Optimized React build
- PM2 or systemd process management
- RDS MySQL with connection pooling
- Error logging to CloudWatch

## 📚 Technology Stack

### Frontend
- **React 18** - UI library
- **CSS Grid** - Layout system
- **Fetch API** - HTTP requests
- **Create React App** - Build tooling

### Backend
- **Node.js 18+** - Runtime
- **Express.js** - Web framework
- **MySQL2** - Database driver
- **Helmet** - Security headers
- **CORS** - Cross-origin requests
- **Compression** - Response compression

## 🔐 Security

- Environment variables for sensitive data
- CORS configuration for allowed origins
- Helmet.js for security headers
- Input validation and sanitization
- Database connection with credentials from AWS Secrets Manager

## 📊 Monitoring

- Health check endpoint (`/health`)
- Application metrics (memory, CPU, uptime)
- Database connection status
- Error logging and handling

This source code demonstrates modern full-stack development practices with proper separation of concerns, security considerations, and production-ready deployment patterns.
