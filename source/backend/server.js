const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(compression());
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS ? process.env.ALLOWED_ORIGINS.split(',') : '*',
  credentials: true
}));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Database connection
let db;

async function connectDB() {
    try {
        db = await mysql.createConnection({
            host: process.env.DB_HOST,
            user: process.env.DB_USER,
            password: process.env.DB_PASSWORD,
            database: process.env.DB_NAME,
            port: process.env.DB_PORT || 3306,
            connectTimeout: 60000,
            acquireTimeout: 60000,
            timeout: 60000
        });
        
        console.log('✅ Connected to MySQL database');
        
        // Create tables and insert sample data
        await initializeDatabase();
        
    } catch (error) {
        console.error('❌ Database connection failed:', error);
        if (process.env.REQUIRE_DB === 'true') {
            process.exit(1);
        }
    }
}

async function initializeDatabase() {
    try {
        // Create categories table
        await db.execute(`
            CREATE TABLE IF NOT EXISTS categories (
                id INT AUTO_INCREMENT PRIMARY KEY,
                name VARCHAR(100) NOT NULL,
                description TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        `);
        
        // Create products table
        await db.execute(`
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
        `);
        
        // Check if data already exists
        const [categories] = await db.execute('SELECT COUNT(*) as count FROM categories');
        if (categories[0].count === 0) {
            await insertSampleData();
        }
        
    } catch (error) {
        console.error('❌ Database initialization failed:', error);
    }
}

async function insertSampleData() {
    try {
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
            ['Classic T-Shirt', 'Comfortable cotton t-shirt in various colors', 29.99, 2, 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400', 100],
            ['Denim Jeans', 'Premium quality denim jeans with perfect fit', 79.99, 2, 'https://images.unsplash.com/photo-1542272604-787c3835535d?w=400', 80],
            ['Winter Jacket', 'Warm and stylish winter jacket for cold weather', 149.99, 2, 'https://images.unsplash.com/photo-1544966503-7cc5ac882d5f?w=400', 45],
            ['Running Shoes', 'Comfortable running shoes for daily exercise', 119.99, 2, 'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=400', 65],
            ['Programming Guide', 'Complete guide to modern programming languages', 49.99, 3, 'https://images.unsplash.com/photo-1532012197267-da84d127e765?w=400', 40],
            ['Fiction Novel', 'Bestselling fiction novel by renowned author', 19.99, 3, 'https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=400', 55],
            ['Cookbook Deluxe', 'Professional cookbook with 500+ recipes', 39.99, 3, 'https://images.unsplash.com/photo-1589829085413-56de8ae18c73?w=400', 35],
            ['Coffee Maker', 'Automatic coffee maker with programmable features', 89.99, 4, 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=400', 25],
            ['Garden Tools Set', 'Complete set of essential garden tools', 69.99, 4, 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=400', 40],
            ['Decorative Lamp', 'Modern decorative lamp for living room', 129.99, 4, 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400', 30],
            ['Yoga Mat', 'Premium non-slip yoga mat for all exercises', 39.99, 5, 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=400', 70],
            ['Basketball', 'Official size basketball for indoor/outdoor play', 24.99, 5, 'https://images.unsplash.com/photo-1546519638-68e109498ffc?w=400', 85],
            ['Fitness Tracker', 'Advanced fitness tracker with heart rate monitor', 199.99, 5, 'https://images.unsplash.com/photo-1575311373937-040b8e1fd5b6?w=400', 50]
        ];
        
        for (const [name, description, price, category_id, image_url, stock_quantity] of productData) {
            await db.execute(
                'INSERT INTO products (name, description, price, category_id, image_url, stock_quantity) VALUES (?, ?, ?, ?, ?, ?)',
                [name, description, price, category_id, image_url, stock_quantity]
            );
        }
        
        console.log('✅ Sample data inserted successfully');
        
    } catch (error) {
        console.error('❌ Error inserting sample data:', error);
    }
}

// Routes

// Health check endpoint
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

// Get all products
app.get('/api/products', async (req, res) => {
    try {
        if (!db) {
            return res.status(503).json({ error: 'Database not available' });
        }
        
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

// Get single product
app.get('/api/products/:id', async (req, res) => {
    try {
        if (!db) {
            return res.status(503).json({ error: 'Database not available' });
        }
        
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

// Get all categories
app.get('/api/categories', async (req, res) => {
    try {
        if (!db) {
            return res.status(503).json({ error: 'Database not available' });
        }
        
        const [categories] = await db.execute('SELECT * FROM categories ORDER BY name');
        res.json(categories);
        
    } catch (error) {
        console.error('Error fetching categories:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Error handling middleware
app.use((err, req, res, next) => {
    console.error('Unhandled error:', err);
    res.status(500).json({ error: 'Internal server error' });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({ error: 'Endpoint not found' });
});

// Start server
async function startServer() {
    await connectDB();
    
    app.listen(PORT, '0.0.0.0', () => {
        console.log(`🚀 Server running on port ${PORT}`);
        console.log(`📊 Environment: ${process.env.NODE_ENV || 'development'}`);
        console.log(`🔗 Health check: http://localhost:${PORT}/health`);
        console.log(`📦 API endpoint: http://localhost:${PORT}/api/products`);
    });
}

// Graceful shutdown
process.on('SIGTERM', async () => {
    console.log('🛑 SIGTERM received, shutting down gracefully');
    if (db) {
        await db.end();
    }
    process.exit(0);
});

process.on('SIGINT', async () => {
    console.log('🛑 SIGINT received, shutting down gracefully');
    if (db) {
        await db.end();
    }
    process.exit(0);
});

startServer().catch(console.error);
