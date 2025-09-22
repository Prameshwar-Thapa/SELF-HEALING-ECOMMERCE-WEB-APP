# AWS Console Step-by-Step Guide: Build Self-Healing E-commerce Infrastructure

## 🎯 Project Overview
Build a complete 3-tier self-healing e-commerce application with auto-scaling, monitoring, and security best practices using only the AWS Console.

**Final Result**: A production-ready e-commerce platform that automatically handles failures and scales with demand.

---

## 📋 Prerequisites
- AWS Account with billing enabled
- Basic understanding of web applications
- Text editor for configuration files
- SSH client (PuTTY for Windows, Terminal for Mac/Linux)

---

## 🏗️ Architecture We're Building

```
Internet → CloudFront → S3 (Frontend) + ALB → EC2 (Auto Scaling) → RDS MySQL
                                    ↓
                              Bastion Host (Management)
```

**Estimated Time**: 3-4 hours  
**Estimated Cost**: $10-15/month for dev environment

---

## 🚀 STEP-BY-STEP IMPLEMENTATION

### PHASE 1: NETWORK FOUNDATION (30 minutes)

#### Step 1: Create VPC
**Service**: VPC → Your VPCs → Create VPC

1. **Click "Create VPC"**
2. **VPC Settings**:
   ```
   Name tag: self-healing-vpc
   IPv4 CIDR block: 10.0.0.0/16
   IPv6 CIDR block: No IPv6 CIDR block
   Tenancy: Default
   ```
3. **Click "Create VPC"**

✅ **Verification**: VPC shows as "Available"

#### Step 2: Create Internet Gateway
**Service**: VPC → Internet Gateways → Create Internet Gateway

1. **Click "Create Internet Gateway"**
2. **Settings**:
   ```
   Name tag: self-healing-igw
   ```
3. **Click "Create Internet Gateway"**
4. **Attach to VPC**:
   - Select the gateway → Actions → Attach to VPC
   - Select "self-healing-vpc" → Attach Internet Gateway

✅ **Verification**: State shows "Attached"

#### Step 3: Create Subnets (9 subnets total)
**Service**: VPC → Subnets → Create Subnet

**Public Subnets** (for ALB, Bastion, NAT Gateways):
```
Subnet 1:
- Name: self-healing-public-subnet-1
- VPC: self-healing-vpc
- Availability Zone: us-east-1a
- IPv4 CIDR: 10.0.1.0/24

Subnet 2:
- Name: self-healing-public-subnet-2
- VPC: self-healing-vpc
- Availability Zone: us-east-1b
- IPv4 CIDR: 10.0.2.0/24

Subnet 3:
- Name: self-healing-public-subnet-3
- VPC: self-healing-vpc
- Availability Zone: us-east-1c
- IPv4 CIDR: 10.0.3.0/24
```

**Private Subnets** (for EC2 instances):
```
Subnet 4:
- Name: self-healing-private-subnet-1
- VPC: self-healing-vpc
- Availability Zone: us-east-1a
- IPv4 CIDR: 10.0.11.0/24

Subnet 5:
- Name: self-healing-private-subnet-2
- VPC: self-healing-vpc
- Availability Zone: us-east-1b
- IPv4 CIDR: 10.0.12.0/24

Subnet 6:
- Name: self-healing-private-subnet-3
- VPC: self-healing-vpc
- Availability Zone: us-east-1c
- IPv4 CIDR: 10.0.13.0/24
```

**Database Subnets** (for RDS):
```
Subnet 7:
- Name: self-healing-db-subnet-1
- VPC: self-healing-vpc
- Availability Zone: us-east-1a
- IPv4 CIDR: 10.0.21.0/24

Subnet 8:
- Name: self-healing-db-subnet-2
- VPC: self-healing-vpc
- Availability Zone: us-east-1b
- IPv4 CIDR: 10.0.22.0/24

Subnet 9:
- Name: self-healing-db-subnet-3
- VPC: self-healing-vpc
- Availability Zone: us-east-1c
- IPv4 CIDR: 10.0.23.0/24
```

**For each subnet**:
1. Click "Create Subnet"
2. Fill in the details above
3. Click "Create Subnet"

✅ **Verification**: All 9 subnets show as "Available"

#### Step 4: Enable Auto-assign Public IP for Public Subnets
**Service**: VPC → Subnets

For each **public subnet** (1, 2, 3):
1. Select the subnet
2. Actions → Modify auto-assign IP settings
3. Check "Enable auto-assign public IPv4 address"
4. Save

#### Step 5: Create NAT Gateways
**Service**: VPC → NAT Gateways → Create NAT Gateway

Create **3 NAT Gateways** (one in each public subnet):

**NAT Gateway 1**:
```
Name: self-healing-nat-1
Subnet: self-healing-public-subnet-1
Connectivity type: Public
Elastic IP allocation ID: Click "Allocate Elastic IP"
```

**NAT Gateway 2**:
```
Name: self-healing-nat-2
Subnet: self-healing-public-subnet-2
Connectivity type: Public
Elastic IP allocation ID: Click "Allocate Elastic IP"
```

**NAT Gateway 3**:
```
Name: self-healing-nat-3
Subnet: self-healing-public-subnet-3
Connectivity type: Public
Elastic IP allocation ID: Click "Allocate Elastic IP"
```

✅ **Verification**: All NAT Gateways show as "Available" (takes 2-3 minutes)

#### Step 6: Create Route Tables
**Service**: VPC → Route Tables → Create Route Table

**Public Route Table**:
1. **Create Route Table**:
   ```
   Name: self-healing-public-rt
   VPC: self-healing-vpc
   ```
2. **Add Route**:
   - Routes tab → Edit routes → Add route
   - Destination: 0.0.0.0/0
   - Target: Internet Gateway → self-healing-igw
   - Save changes
3. **Associate Subnets**:
   - Subnet associations tab → Edit subnet associations
   - Select all 3 public subnets
   - Save associations

**Private Route Tables** (create 3 separate ones):

**Private Route Table 1**:
```
Name: self-healing-private-rt-1
VPC: self-healing-vpc
Route: 0.0.0.0/0 → self-healing-nat-1
Associated Subnet: self-healing-private-subnet-1
```

**Private Route Table 2**:
```
Name: self-healing-private-rt-2
VPC: self-healing-vpc
Route: 0.0.0.0/0 → self-healing-nat-2
Associated Subnet: self-healing-private-subnet-2
```

**Private Route Table 3**:
```
Name: self-healing-private-rt-3
VPC: self-healing-vpc
Route: 0.0.0.0/0 → self-healing-nat-3
Associated Subnet: self-healing-private-subnet-3
```

✅ **Verification**: Route tables show correct routes and subnet associations

---

### PHASE 2: SECURITY FOUNDATION (20 minutes)

#### Step 7: Create Security Groups
**Service**: EC2 → Security Groups → Create Security Group

**ALB Security Group**:
```
Name: self-healing-alb-sg
Description: Security group for Application Load Balancer
VPC: self-healing-vpc

Inbound Rules:
- Type: HTTP, Port: 80, Source: 0.0.0.0/0
- Type: HTTPS, Port: 443, Source: 0.0.0.0/0

Outbound Rules:
- Type: All Traffic, Destination: 0.0.0.0/0
```

**EC2 Security Group**:
```
Name: self-healing-ec2-sg
Description: Security group for EC2 instances
VPC: self-healing-vpc

Inbound Rules:
- Type: Custom TCP, Port: 3000, Source: self-healing-alb-sg
- Type: SSH, Port: 22, Source: self-healing-bastion-sg (create this later)

Outbound Rules:
- Type: All Traffic, Destination: 0.0.0.0/0
```

**RDS Security Group**:
```
Name: self-healing-rds-sg
Description: Security group for RDS database
VPC: self-healing-vpc

Inbound Rules:
- Type: MySQL/Aurora, Port: 3306, Source: self-healing-ec2-sg
- Type: MySQL/Aurora, Port: 3306, Source: self-healing-bastion-sg (create this later)

Outbound Rules:
- None (delete default outbound rule)
```

**Bastion Security Group**:
```
Name: self-healing-bastion-sg
Description: Security group for Bastion host
VPC: self-healing-vpc

Inbound Rules:
- Type: SSH, Port: 22, Source: 0.0.0.0/0 (or your IP for better security)

Outbound Rules:
- Type: All Traffic, Destination: 0.0.0.0/0
```

**After creating all security groups**, go back and update:
- **EC2 Security Group**: Add SSH rule with source "self-healing-bastion-sg"
- **RDS Security Group**: Add MySQL rule with source "self-healing-bastion-sg"

✅ **Verification**: All 4 security groups created with correct rules

---

### PHASE 3: IAM ROLES & POLICIES (15 minutes)

#### Step 8: Create IAM Role for EC2 Instances
**Service**: IAM → Roles → Create Role

1. **Select Trusted Entity**:
   - Trusted entity type: AWS service
   - Use case: EC2
   - Click Next

2. **Add Permissions** (attach these managed policies):
   - `AmazonSSMManagedInstanceCore`
   - `CloudWatchAgentServerPolicy`
   - `AmazonS3ReadOnlyAccess`

3. **Create Custom Policy** for Secrets Manager:
   - Click "Create policy" (opens new tab)
   - JSON tab, paste this policy:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ReadAppSecrets",
            "Effect": "Allow",
            "Action": "secretsmanager:GetSecretValue",
            "Resource": [
                "arn:aws:secretsmanager:us-east-1:*:secret:self-healing-dev-db-password-*",
                "arn:aws:secretsmanager:us-east-1:*:secret:self-healing/dev/application/config/v1-*",
                "arn:aws:secretsmanager:us-east-1:*:secret:self-healing/dev/application/jwt/v1-*",
                "arn:aws:secretsmanager:us-east-1:*:secret:self-healing-dev-bastion-private-key-*"
            ]
        },
        {
            "Sid": "S3BackendAccess",
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::self-healing-backend-bucket-*",
                "arn:aws:s3:::self-healing-backend-bucket-*/*"
            ]
        },
        {
            "Sid": "CloudWatchLogs",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:DescribeLogStreams"
            ],
            "Resource": "arn:aws:logs:us-east-1:*:log-group:/aws/ec2/*"
        }
    ]
}
```

   - Name: `self-healing-custom-policy`
   - Create policy
   - Go back to role creation tab

4. **Attach Custom Policy**:
   - Refresh and search for "self-healing-custom-policy"
   - Select it

5. **Role Details**:
   ```
   Role name: self-healing-ec2-role
   Description: IAM role for self-healing EC2 instances
   ```

6. **Create Role**

✅ **Verification**: Role created with 4 policies attached

---

### PHASE 4: SECRETS MANAGEMENT (10 minutes)

#### Step 9: Create Secrets in Secrets Manager
**Service**: Secrets Manager → Secrets → Store a new secret

**Database Secret**:
1. **Secret Type**: Credentials for Amazon RDS database
2. **Credentials**:
   ```
   User name: ecommerceadmin
   Password: Generate a password (32 characters, exclude quotes)
   ```
3. **Database**: We'll select this later
4. **Secret Name**: `self-healing-dev-db-password`
5. **Store Secret**

**Application Config Secret**:
1. **Secret Type**: Other type of secret
2. **Key/Value Pairs**:
   ```
   NODE_ENV: production
   PORT: 3000
   API_URL: (leave blank for now)
   ```
3. **Secret Name**: `self-healing/dev/application/config/v1`
4. **Store Secret**

**JWT Secret**:
1. **Secret Type**: Other type of secret
2. **Key/Value Pairs**:
   ```
   JWT_SECRET: (generate 64-character random string)
   ```
   Use this command to generate: `openssl rand -base64 48`
3. **Secret Name**: `self-healing/dev/application/jwt/v1`
4. **Store Secret**

✅ **Verification**: 3 secrets created and show as "Active"

---

### PHASE 5: STORAGE SETUP (15 minutes)

#### Step 10: Create S3 Buckets
**Service**: S3 → Buckets → Create Bucket

**Frontend Bucket**:
```
Bucket name: self-healing-frontend-bucket-[random-suffix]
Region: US East (N. Virginia) us-east-1
Block all public access: Keep checked (we'll use CloudFront)
Bucket versioning: Enable
Default encryption: Enable (SSE-S3)
```

**Backend Bucket**:
```
Bucket name: self-healing-backend-bucket-[random-suffix]
Region: US East (N. Virginia) us-east-1
Block all public access: Keep checked
Bucket versioning: Enable
Default encryption: Enable (SSE-S3)
```

#### Step 11: Upload Application Files

**Frontend Files** (create these locally first):

Create `index.html`:
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8" />
    <link rel="icon" href="/favicon.ico" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>E-commerce App</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 800px; margin: 0 auto; }
        .product { border: 1px solid #ddd; padding: 20px; margin: 10px 0; }
        button { background: #007bff; color: white; padding: 10px 20px; border: none; cursor: pointer; }
    </style>
</head>
<body>
    <div class="container">
        <h1>E-commerce Store</h1>
        <div id="products"></div>
    </div>
    <script>
        async function loadProducts() {
            try {
                const response = await fetch('/api/products');
                const data = await response.json();
                const productsDiv = document.getElementById('products');
                productsDiv.innerHTML = data.products.map(product => `
                    <div class="product">
                        <h3>${product.name}</h3>
                        <p>${product.description}</p>
                        <p>Price: $${product.price}</p>
                        <button>Add to Cart</button>
                    </div>
                `).join('');
            } catch (error) {
                document.getElementById('products').innerHTML = '<p>Error loading products</p>';
            }
        }
        loadProducts();
    </script>
</body>
</html>
```

Upload to frontend bucket:
- `index.html`
- Create empty `favicon.ico` file

**Backend Files**:

Create `backend-deployment.zip` with these files:

`package.json`:
```json
{
  "name": "ecommerce-backend",
  "version": "1.0.0",
  "main": "server.js",
  "dependencies": {
    "express": "^4.18.0",
    "mysql2": "^3.6.0",
    "cors": "^2.8.5",
    "helmet": "^7.0.0",
    "dotenv": "^16.3.0"
  },
  "scripts": {
    "start": "node server.js"
  }
}
```

`server.js`:
```javascript
const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');
const helmet = require('helmet');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Database connection
let db;
async function connectDB() {
    try {
        db = await mysql.createConnection({
            host: process.env.DB_HOST,
            user: process.env.DB_USER,
            password: process.env.DB_PASSWORD,
            database: process.env.DB_NAME,
            port: process.env.DB_PORT || 3306
        });
        console.log('Connected to MySQL database');
        
        // Create tables if they don't exist
        await createTables();
        await insertSampleData();
    } catch (error) {
        console.error('Database connection failed:', error);
        process.exit(1);
    }
}

async function createTables() {
    const createCategoriesTable = `
        CREATE TABLE IF NOT EXISTS categories (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(100) NOT NULL,
            description TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    `;
    
    const createProductsTable = `
        CREATE TABLE IF NOT EXISTS products (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(200) NOT NULL,
            description TEXT,
            price DECIMAL(10,2) NOT NULL,
            category_id INT,
            image_url VARCHAR(500),
            stock_quantity INT DEFAULT 0,
            is_active BOOLEAN DEFAULT TRUE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            FOREIGN KEY (category_id) REFERENCES categories(id)
        )
    `;
    
    await db.execute(createCategoriesTable);
    await db.execute(createProductsTable);
}

async function insertSampleData() {
    // Check if data already exists
    const [categories] = await db.execute('SELECT COUNT(*) as count FROM categories');
    if (categories[0].count > 0) return;
    
    // Insert categories
    const categoryData = [
        ['Electronics', 'Electronic devices and gadgets'],
        ['Clothing', 'Fashion and apparel'],
        ['Books', 'Books and educational materials'],
        ['Home & Garden', 'Home improvement and garden supplies'],
        ['Sports', 'Sports and fitness equipment']
    ];
    
    for (const [name, description] of categoryData) {
        await db.execute('INSERT INTO categories (name, description) VALUES (?, ?)', [name, description]);
    }
    
    // Insert products
    const productData = [
        ['Smartphone Pro Max', 'Latest flagship smartphone with advanced features', 999.99, 1, 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=400', 50],
        ['Wireless Headphones', 'Premium noise-cancelling wireless headphones', 299.99, 1, 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400', 75],
        ['Laptop Ultra', 'High-performance laptop for professionals', 1299.99, 1, 'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=400', 30],
        ['Smart Watch', 'Fitness tracking smartwatch with health monitoring', 399.99, 1, 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400', 60],
        ['Classic T-Shirt', 'Comfortable cotton t-shirt in various colors', 29.99, 2, 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400', 100]
    ];
    
    for (const [name, description, price, category_id, image_url, stock_quantity] of productData) {
        await db.execute(
            'INSERT INTO products (name, description, price, category_id, image_url, stock_quantity) VALUES (?, ?, ?, ?, ?, ?)',
            [name, description, price, category_id, image_url, stock_quantity]
        );
    }
}

// Routes
app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        environment: process.env.NODE_ENV || 'development',
        version: '1.0.0',
        checks: {
            database: db ? 'healthy' : 'unhealthy',
            memory: {
                used: Math.round(process.memoryUsage().heapUsed / 1024 / 1024) + ' MB',
                total: Math.round(process.memoryUsage().heapTotal / 1024 / 1024) + ' MB'
            },
            cpu: {
                usage: process.cpuUsage()
            }
        }
    });
});

app.get('/api/products', async (req, res) => {
    try {
        const [products] = await db.execute(`
            SELECT p.*, c.name as category_name 
            FROM products p 
            LEFT JOIN categories c ON p.category_id = c.id 
            WHERE p.is_active = TRUE 
            ORDER BY p.created_at DESC
        `);
        
        res.json({
            products,
            pagination: {
                currentPage: 1,
                totalPages: 1,
                totalItems: products.length,
                itemsPerPage: products.length,
                hasNextPage: false,
                hasPrevPage: false
            }
        });
    } catch (error) {
        console.error('Error fetching products:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.get('/api/products/:id', async (req, res) => {
    try {
        const [products] = await db.execute(`
            SELECT p.*, c.name as category_name 
            FROM products p 
            LEFT JOIN categories c ON p.category_id = c.id 
            WHERE p.id = ? AND p.is_active = TRUE
        `, [req.params.id]);
        
        if (products.length === 0) {
            return res.status(404).json({ error: 'Product not found' });
        }
        
        res.json(products[0]);
    } catch (error) {
        console.error('Error fetching product:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.get('/api/categories', async (req, res) => {
    try {
        const [categories] = await db.execute('SELECT * FROM categories ORDER BY name');
        res.json(categories);
    } catch (error) {
        console.error('Error fetching categories:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Start server
async function startServer() {
    await connectDB();
    app.listen(PORT, '0.0.0.0', () => {
        console.log(`Server running on port ${PORT}`);
        console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
    });
}

startServer().catch(console.error);
```

Upload `backend-deployment.zip` to backend bucket.

✅ **Verification**: Both buckets contain the required files

---

### PHASE 6: DATABASE SETUP (20 minutes)

#### Step 12: Create DB Subnet Group
**Service**: RDS → Subnet Groups → Create DB Subnet Group

```
Name: self-healing-db-subnet-group
Description: Database subnet group for self-healing project
VPC: self-healing-vpc
Availability Zones: us-east-1a, us-east-1b, us-east-1c
Subnets: 
- self-healing-db-subnet-1 (10.0.21.0/24)
- self-healing-db-subnet-2 (10.0.22.0/24)
- self-healing-db-subnet-3 (10.0.23.0/24)
```

#### Step 13: Create RDS MySQL Database
**Service**: RDS → Databases → Create Database

1. **Database Creation Method**: Standard create
2. **Engine Options**:
   ```
   Engine type: MySQL
   Version: MySQL 8.0.35 (or latest)
   ```

3. **Templates**: Free tier (for learning) or Dev/Test

4. **Settings**:
   ```
   DB instance identifier: self-healing-dev-db
   Master username: ecommerceadmin
   Master password: Use the password from Secrets Manager
   ```

5. **Instance Configuration**:
   ```
   DB instance class: db.t3.micro (free tier eligible)
   ```

6. **Storage**:
   ```
   Storage type: General Purpose SSD (gp2)
   Allocated storage: 20 GB
   Enable storage autoscaling: Yes
   Maximum storage threshold: 100 GB
   ```

7. **Connectivity**:
   ```
   VPC: self-healing-vpc
   DB subnet group: self-healing-db-subnet-group
   Public access: No
   VPC security groups: Choose existing → self-healing-rds-sg
   Availability Zone: No preference
   Database port: 3306
   ```

8. **Database Authentication**: Password authentication

9. **Additional Configuration**:
   ```
   Initial database name: ecommerce_db
   DB parameter group: default.mysql8.0
   Option group: default:mysql-8-0
   Backup retention period: 7 days
   Backup window: No preference
   Copy tags to snapshots: Yes
   Enable encryption: Yes (default key)
   Enable Performance Insights: No (to save costs)
   Enable Enhanced monitoring: No (to save costs)
   Enable auto minor version upgrade: Yes
   Maintenance window: No preference
   Enable deletion protection: No (for dev environment)
   ```

10. **Create Database**

⏱️ **Wait Time**: 10-15 minutes for database to become available

✅ **Verification**: Database status shows "Available"

#### Step 14: Update Database Secret
**Service**: Secrets Manager → Secrets → self-healing-dev-db-password

1. **Retrieve secret value** and note the endpoint
2. **Edit secret** and update:
   ```json
   {
     "username": "ecommerceadmin",
     "password": "your-generated-password",
     "engine": "mysql",
     "host": "self-healing-dev-db.xxxxx.us-east-1.rds.amazonaws.com",
     "port": 3306,
     "dbname": "ecommerce_db"
   }
   ```

---

### PHASE 7: COMPUTE INFRASTRUCTURE (25 minutes)

#### Step 15: Create Key Pair for Bastion Host
**Service**: EC2 → Key Pairs → Create Key Pair

```
Name: self-healing-bastion-key
Key pair type: RSA
Private key file format: .pem
```

**Download and save** the private key file securely.

#### Step 16: Create User Data Script
Create a file called `user-data.sh` with this content:

```bash
#!/bin/bash
# E-commerce backend bootstrap (Amazon Linux 2023)
set -euo pipefail
exec > >(tee -a /var/log/user-data.log) 2>&1

# Configuration
REGION="us-east-1"
ARTIFACT_S3="s3://self-healing-backend-bucket-YOUR-SUFFIX/backend-deployment.zip"
DB_HOST="self-healing-dev-db.xxxxx.us-east-1.rds.amazonaws.com"
APP_PORT="3000"
HOST_BIND="0.0.0.0"
JWT_EXPIRES_IN="24h"

# Secrets Manager names
SM_DB_SECRET="self-healing-dev-db-password"
SM_CFG_SECRET="self-healing/dev/application/config/v1"
SM_JWT_SECRET="self-healing/dev/application/jwt/v1"

echo "[user-data] Installing packages"
dnf -y install unzip nodejs npm awscli jq rsync

APP_ROOT="/opt/ecommerce-app"
BACKEND_DIR="$APP_ROOT/backend"
LOG_DIR="$APP_ROOT/logs"
TMP_ZIP="/tmp/backend.zip"

echo "[user-data] Preparing directories"
rm -rf "$BACKEND_DIR"
mkdir -p "$BACKEND_DIR" "$LOG_DIR"
chown -R ec2-user:ec2-user "$APP_ROOT"

echo "[user-data] Downloading artifact: $ARTIFACT_S3"
for i in {1..5}; do
  if aws s3 cp "$ARTIFACT_S3" "$TMP_ZIP" --region "$REGION"; then
    break
  fi
  echo "[user-data] S3 download attempt $i failed; retrying in 5s..."
  sleep 5
done
test -s "$TMP_ZIP" || { echo "[user-data][ERROR] Artifact not found"; exit 1; }

echo "[user-data] Unpacking artifact"
unzip -oq "$TMP_ZIP" -d "$BACKEND_DIR"

# Check if zip has a top-level folder
if [ ! -f "$BACKEND_DIR/package.json" ]; then
  SUBDIR="$(find "$BACKEND_DIR" -mindepth 1 -maxdepth 1 -type d | head -n1 || true)"
  if [ -n "$SUBDIR" ] && [ -f "$SUBDIR/package.json" ]; then
    echo "[user-data] Flattening $SUBDIR into $BACKEND_DIR"
    rsync -a "$SUBDIR/." "$BACKEND_DIR/"
    rm -rf "$SUBDIR"
  fi
fi

test -f "$BACKEND_DIR/package.json" || { echo "[user-data][ERROR] package.json missing"; exit 2; }
test -f "$BACKEND_DIR/server.js" || { echo "[user-data][ERROR] server.js missing"; exit 3; }

echo "[user-data] Installing Node dependencies"
cd "$BACKEND_DIR"
if [ -f package-lock.json ]; then
  npm ci --omit=dev || npm ci
else
  npm install --omit=dev || npm install
fi

# Helper function to get secrets
get_secret_string() {
  aws secretsmanager get-secret-value \
    --secret-id "$1" \
    --query SecretString \
    --output text \
    --region "$REGION" 2>/dev/null || true
}

# Fetch database secret
echo "[user-data] Fetching DB secret: $SM_DB_SECRET"
DB_RAW="$(get_secret_string "$SM_DB_SECRET")"
[ -n "${DB_RAW:-}" ] || { echo "[user-data][ERROR] Failed to read DB secret"; exit 4; }

if echo "$DB_RAW" | jq -e . >/dev/null 2>&1; then
  DB_USER="$(echo "$DB_RAW" | jq -r '.username // .user // .DB_USER // empty')"
  DB_PASSWORD="$(echo "$DB_RAW" | jq -r '.password // .DB_PASSWORD // .db_password // empty')"
  DB_NAME="$(echo "$DB_RAW" | jq -r '.dbname // .db_name // .DB_NAME // empty')"
else
  DB_USER=""
  DB_NAME=""
  DB_PASSWORD="$DB_RAW"
fi
[ -n "${DB_PASSWORD:-}" ] || { echo "[user-data][ERROR] DB password missing"; exit 4; }

# Fetch app config secret
echo "[user-data] Fetching config secret: $SM_CFG_SECRET"
CFG_RAW="$(get_secret_string "$SM_CFG_SECRET")"
CLOUDFRONT_URL=""
API_ALLOWED_ORIGINS=""
if [ -n "${CFG_RAW:-}" ]; then
  if echo "$CFG_RAW" | jq -e . >/dev/null 2>&1; then
    CLOUDFRONT_URL="$(echo "$CFG_RAW" | jq -r '.CLOUDFRONT_URL // .cloudfront_url // empty')"
    API_ALLOWED_ORIGINS="$(echo "$CFG_RAW" | jq -r '.ALLOWED_ORIGINS // .allowed_origins // empty')"
    if [ -z "${DB_USER}" ]; then DB_USER="$(echo "$CFG_RAW" | jq -r '.DB_USER // empty')"; fi
    if [ -z "${DB_NAME}" ]; then DB_NAME="$(echo "$CFG_RAW" | jq -r '.DB_NAME // empty')"; fi
  else
    case "$CFG_RAW" in http://*|https://*) CLOUDFRONT_URL="$CFG_RAW" ;; esac
  fi
fi
DB_USER="${DB_USER:-ecommerceadmin}"
DB_NAME="${DB_NAME:-ecommerce_db}"

# Fetch JWT secret
echo "[user-data] Fetching JWT secret: $SM_JWT_SECRET"
JWT_RAW="$(get_secret_string "$SM_JWT_SECRET")"
[ -n "${JWT_RAW:-}" ] || { echo "[user-data][ERROR] Failed to read JWT secret"; exit 5; }
if echo "$JWT_RAW" | jq -e . >/dev/null 2>&1; then
  JWT_SECRET_VAL="$(echo "$JWT_RAW" | jq -r '.JWT_SECRET // .jwt // .jwt_secret // empty')"
else
  JWT_SECRET_VAL="$JWT_RAW"
fi
[ -n "${JWT_SECRET_VAL:-}" ] || { echo "[user-data][ERROR] JWT secret value missing"; exit 5; }

echo "[user-data] Writing .env"
umask 077
cat >"$BACKEND_DIR/.env" <<EOF
NODE_ENV=production
HOST=${HOST_BIND}
PORT=${APP_PORT}

# --- RDS/MySQL ---
DB_HOST=${DB_HOST}
DB_PORT=3306
DB_NAME=${DB_NAME}
DB_USER=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}

# --- Security / JWT ---
JWT_SECRET=${JWT_SECRET_VAL}
JWT_EXPIRES_IN=${JWT_EXPIRES_IN}

# --- CORS allowed origins ---
CLOUDFRONT_URL=${CLOUDFRONT_URL}
ALLOWED_ORIGINS=${API_ALLOWED_ORIGINS}

# --- Logging & Region ---
LOG_LEVEL=info
AWS_REGION=${REGION}
AWS_DEFAULT_REGION=${REGION}

# --- App behavior ---
REQUIRE_DB=true
EOF
chown ec2-user:ec2-user "$BACKEND_DIR/.env"
chmod 600 "$BACKEND_DIR/.env"

echo "[user-data] Creating systemd unit"
cat >/etc/systemd/system/ecommerce-backend.service <<'EOF'
[Unit]
Description=E-commerce Backend API
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=ec2-user
Group=ec2-user
WorkingDirectory=/opt/ecommerce-app/backend
EnvironmentFile=/opt/ecommerce-app/backend/.env
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=5
LimitNOFILE=65536
StandardOutput=journal
StandardError=journal
SyslogIdentifier=ecommerce-backend

[Install]
WantedBy=multi-user.target
EOF

echo "[user-data] Enabling & starting service"
systemctl daemon-reload
systemctl enable ecommerce-backend
systemctl start ecommerce-backend

echo "[user-data] Completed successfully"
```

**Important**: Replace `YOUR-SUFFIX` with your actual S3 bucket suffix and update the DB_HOST with your actual RDS endpoint.

#### Step 17: Create Launch Template
**Service**: EC2 → Launch Templates → Create Launch Template

```
Launch template name: self-healing-launch-template
Template version description: Initial version for self-healing app

Application and OS Images:
- Amazon Machine Image (AMI): Amazon Linux 2023 AMI
- Architecture: 64-bit (x86)

Instance type: t3.micro

Key pair: self-healing-bastion-key

Network settings:
- Subnet: Don't include in launch template
- Security groups: self-healing-ec2-sg

Storage (volumes):
- Volume 1 (AMI Root): 8 GiB, gp3, Encrypted

Resource tags:
- Key: Name, Value: self-healing-backend
- Key: Project, Value: self-healing
- Key: Environment, Value: dev

Advanced details:
- IAM instance profile: self-healing-ec2-role
- User data: Paste the user-data.sh script content (base64 encoding not needed)
```

#### Step 18: Create Bastion Host
**Service**: EC2 → Instances → Launch Instance

```
Name: self-healing-bastion-host

Application and OS Images:
- Amazon Linux 2023 AMI

Instance type: t3.micro

Key pair: self-healing-bastion-key

Network settings:
- VPC: self-healing-vpc
- Subnet: self-healing-public-subnet-1
- Auto-assign public IP: Enable
- Security group: self-healing-bastion-sg

Configure storage: 8 GiB gp3

Advanced details:
- IAM instance profile: self-healing-ec2-role

User data:
```bash
#!/bin/bash
yum update -y
yum install -y amazon-ssm-agent mysql
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent
echo "Bastion host setup completed" > /var/log/bastion-setup.log
```

**Launch Instance**

✅ **Verification**: Bastion host is running and has a public IP

---

### PHASE 8: LOAD BALANCING & AUTO SCALING (20 minutes)

#### Step 19: Create Target Group
**Service**: EC2 → Target Groups → Create Target Group

```
Target type: Instances
Target group name: self-healing-target-group
Protocol: HTTP
Port: 3000
VPC: self-healing-vpc

Health checks:
- Health check protocol: HTTP
- Health check path: /health
- Health check port: Traffic port
- Healthy threshold: 2
- Unhealthy threshold: 3
- Timeout: 5 seconds
- Interval: 30 seconds
- Success codes: 200

Tags:
- Key: Name, Value: self-healing-target-group
- Key: Project, Value: self-healing
```

#### Step 20: Create Application Load Balancer
**Service**: EC2 → Load Balancers → Create Load Balancer

**Choose Application Load Balancer**

```
Load balancer name: self-healing-alb
Scheme: Internet-facing
IP address type: IPv4

Network mapping:
- VPC: self-healing-vpc
- Mappings: 
  - us-east-1a: self-healing-public-subnet-1
  - us-east-1b: self-healing-public-subnet-2
  - us-east-1c: self-healing-public-subnet-3

Security groups: self-healing-alb-sg

Listeners and routing:
- Protocol: HTTP
- Port: 80
- Default action: Forward to self-healing-target-group

Tags:
- Key: Name, Value: self-healing-alb
- Key: Project, Value: self-healing
```

**Create Load Balancer**

✅ **Verification**: ALB shows as "Active" (takes 2-3 minutes)

#### Step 21: Create Auto Scaling Group
**Service**: EC2 → Auto Scaling Groups → Create Auto Scaling Group

**Step 1: Choose launch template**
```
Auto Scaling group name: self-healing-asg
Launch template: self-healing-launch-template
Version: Latest
```

**Step 2: Choose instance launch options**
```
VPC: self-healing-vpc
Subnets: 
- self-healing-private-subnet-1
- self-healing-private-subnet-2
- self-healing-private-subnet-3
```

**Step 3: Configure advanced options**
```
Load balancing: Attach to an existing load balancer
Target groups: self-healing-target-group

Health checks:
- ELB health checks: Turn on
- Health check grace period: 300 seconds

Additional settings:
- Enable group metrics collection within CloudWatch: Check
```

**Step 4: Configure group size and scaling policies**
```
Group size:
- Desired capacity: 2
- Minimum capacity: 1
- Maximum capacity: 3

Scaling policies: None (we'll add later if needed)
```

**Step 5: Add notifications** (Skip)

**Step 6: Add tags**
```
Key: Name, Value: self-healing-asg-instance
Key: Project, Value: self-healing
Key: Environment, Value: dev
```

**Create Auto Scaling Group**

⏱️ **Wait Time**: 5-10 minutes for instances to launch and become healthy

✅ **Verification**: 
- 2 instances running in private subnets
- Target group shows 2 healthy targets
- ALB health checks passing

---

### PHASE 9: CONTENT DELIVERY (15 minutes)

#### Step 22: Create CloudFront Distribution
**Service**: CloudFront → Distributions → Create Distribution

**Origin Settings**:

**Origin 1 (S3 Frontend)**:
```
Origin domain: self-healing-frontend-bucket-YOUR-SUFFIX.s3.us-east-1.amazonaws.com
Name: frontend-s3
Origin path: (leave blank)
Origin access: Origin access control settings (recommended)
Origin access control: Create new OAC
  - Name: frontend-s3-oac
  - Signing behavior: Sign requests
  - Origin type: S3
```

**Default Cache Behavior**:
```
Path pattern: Default (*)
Compress objects automatically: Yes
Viewer protocol policy: Redirect HTTP to HTTPS
Allowed HTTP methods: GET, HEAD
Restrict viewer access: No
Cache policy: Managed-CachingOptimized
Origin request policy: Managed-CORS-S3Origin
Response headers policy: Managed-SecurityHeadersPolicy
```

**Distribution Settings**:
```
Price class: Use all edge locations (best performance)
Supported HTTP versions: HTTP/2 and HTTP/3
Default root object: index.html
```

**Create Distribution**

#### Step 23: Add ALB Origin to CloudFront
After the distribution is created:

1. **Go to Origins tab** → Create Origin

**Origin 2 (ALB Backend)**:
```
Origin domain: self-healing-alb-XXXXXXXXX.us-east-1.elb.amazonaws.com
Name: backend-alb
Protocol: HTTP only
HTTP port: 80
Origin path: (leave blank)
```

2. **Go to Behaviors tab** → Create Behavior

**API Behavior**:
```
Path pattern: /api/*
Origin: backend-alb
Compress objects automatically: Yes
Viewer protocol policy: Redirect HTTP to HTTPS
Allowed HTTP methods: GET, HEAD, OPTIONS, PUT, POST, PATCH, DELETE
Cache policy: Managed-CachingDisabled
Origin request policy: Managed-AllViewer
Response headers policy: Managed-CORS-With-Preflight
```

**Health Behavior**:
```
Path pattern: /health
Origin: backend-alb
Compress objects automatically: No
Viewer protocol policy: Redirect HTTP to HTTPS
Allowed HTTP methods: GET, HEAD
Cache policy: Managed-CachingDisabled
Origin request policy: Managed-AllViewer
```

#### Step 24: Update S3 Bucket Policy
CloudFront will provide a bucket policy. Copy and apply it:

**Service**: S3 → Buckets → self-healing-frontend-bucket → Permissions → Bucket Policy

Paste the policy provided by CloudFront (it will look like this):

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowCloudFrontServicePrincipal",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudfront.amazonaws.com"
            },
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::self-healing-frontend-bucket-YOUR-SUFFIX/*",
            "Condition": {
                "StringEquals": {
                    "AWS:SourceArn": "arn:aws:cloudfront::YOUR-ACCOUNT:distribution/YOUR-DISTRIBUTION-ID"
                }
            }
        }
    ]
}
```

⏱️ **Wait Time**: 15-20 minutes for CloudFront deployment

✅ **Verification**: Distribution status shows "Deployed"

---

### PHASE 10: TESTING & VALIDATION (15 minutes)

#### Step 25: Test the Complete Application

**Get CloudFront Domain**:
- Go to CloudFront → Distributions
- Copy the distribution domain name (e.g., `d1234567890123.cloudfront.net`)

**Test Frontend**:
```bash
curl -I https://YOUR-CLOUDFRONT-DOMAIN.cloudfront.net/
# Should return 200 OK with HTML content
```

**Test API Health**:
```bash
curl -i https://YOUR-CLOUDFRONT-DOMAIN.cloudfront.net/health
# Should return JSON with status: "healthy"
```

**Test API Products**:
```bash
curl -i https://YOUR-CLOUDFRONT-DOMAIN.cloudfront.net/api/products
# Should return JSON with product list
```

**Test in Browser**:
- Open `https://YOUR-CLOUDFRONT-DOMAIN.cloudfront.net/`
- Should see the e-commerce page with products loaded

#### Step 26: Test Auto-Healing
**Terminate an Instance**:
1. Go to EC2 → Instances
2. Select one of the backend instances
3. Instance State → Terminate Instance

**Verify Auto-Healing**:
- Auto Scaling Group should launch a new instance within 5 minutes
- Target Group should show the new instance becoming healthy
- Application should remain accessible throughout

#### Step 27: Test Bastion Access
**Connect to Bastion**:
```bash
# Use the private key you downloaded
chmod 600 self-healing-bastion-key.pem
ssh -i self-healing-bastion-key.pem ec2-user@BASTION-PUBLIC-IP
```

**From Bastion, test backend instances**:
```bash
# Test application instances
curl http://10.0.11.X:3000/health
curl http://10.0.12.X:3000/health

# Test database connection
mysql -h self-healing-dev-db.XXXXX.us-east-1.rds.amazonaws.com -u ecommerceadmin -p
```

---

## 🎉 CONGRATULATIONS!

You have successfully built a complete self-healing e-commerce infrastructure on AWS! 

### 🏆 What You've Accomplished:

✅ **3-Tier Architecture**: Presentation, Application, and Database layers  
✅ **High Availability**: Multi-AZ deployment with auto-scaling  
✅ **Security**: IAM roles, Security Groups, Secrets Manager  
✅ **Monitoring**: CloudWatch integration and health checks  
✅ **Content Delivery**: Global CloudFront distribution  
✅ **Auto-Healing**: Automatic instance replacement on failure  
✅ **Scalability**: Auto Scaling Group handles traffic spikes  

### 📊 Architecture Summary:
- **VPC**: 10.0.0.0/16 with 9 subnets across 3 AZs
- **Compute**: Auto Scaling Group with 1-3 t3.micro instances
- **Database**: RDS MySQL 8.0 with automated backups
- **Storage**: S3 buckets for frontend and backend artifacts
- **CDN**: CloudFront with global edge locations
- **Security**: IAM roles, Security Groups, encrypted storage
- **Management**: Bastion host for troubleshooting

### 💰 Estimated Monthly Cost (Dev Environment):
- **EC2 Instances**: ~$15-45 (1-3 t3.micro)
- **RDS MySQL**: ~$15 (db.t3.micro)
- **ALB**: ~$16
- **NAT Gateways**: ~$45 (3 gateways)
- **S3 Storage**: ~$1-5
- **CloudFront**: ~$1-10
- **Total**: ~$93-137/month

### 🔧 Next Steps:
1. **Set up monitoring alerts** in CloudWatch
2. **Configure SSL certificate** for custom domain
3. **Implement CI/CD pipeline** for deployments
4. **Add ElastiCache** for database caching
5. **Set up backup strategies** for disaster recovery

### 🚨 Important Security Notes:
- **Change default passwords** in production
- **Restrict SSH access** to specific IP ranges
- **Enable MFA** for AWS root account
- **Regular security audits** and updates
- **Monitor costs** and set up billing alerts

**Well done!** You now have hands-on experience with AWS core services and can build production-ready infrastructure. 🎊
