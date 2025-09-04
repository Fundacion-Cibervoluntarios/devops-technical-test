const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const { Pool } = require('pg');
const { createClient } = require('redis');

const app = express();
const PORT = process.env.PORT || 8080;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Database connections (with fallbacks for testing)
let db, redis;

// PostgreSQL connection
if (process.env.DATABASE_URL) {
  db = new Pool({
    connectionString: process.env.DATABASE_URL,
  });
} else {
  console.log('DATABASE_URL not set, using mock data');
}

// Redis connection
if (process.env.REDIS_URL) {
  redis = createClient({ url: process.env.REDIS_URL });
  redis.connect().catch(console.error);
} else {
  console.log('REDIS_URL not set, caching disabled');
}

// Mock data for when database is not available
const mockProducts = [
  { id: 1, name: 'DevOps T-Shirt', price: 25.99, category: 'apparel' },
  { id: 2, name: 'Kubernetes Mug', price: 15.50, category: 'accessories' },
  { id: 3, name: 'Docker Stickers', price: 5.99, category: 'accessories' },
  { id: 4, name: 'Terraform Guide', price: 39.99, category: 'books' },
  { id: 5, name: 'Azure Certification', price: 199.99, category: 'courses' },
];

// Routes
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    version: process.env.npm_package_version || '1.0.0'
  });
});

app.get('/ready', async (req, res) => {
  const checks = {
    database: false,
    redis: false,
    overall: false
  };

  // Check database
  if (db) {
    try {
      await db.query('SELECT 1');
      checks.database = true;
    } catch (err) {
      console.error('Database check failed:', err.message);
    }
  } else {
    checks.database = true; // Mock mode
  }

  // Check Redis
  if (redis && redis.isOpen) {
    try {
      await redis.ping();
      checks.redis = true;
    } catch (err) {
      console.error('Redis check failed:', err.message);
    }
  } else {
    checks.redis = true; // Mock mode
  }

  checks.overall = checks.database && checks.redis;
  
  res.status(checks.overall ? 200 : 503).json(checks);
});

app.get('/api/products', async (req, res) => {
  try {
    let products;
    
    // Try Redis cache first
    if (redis && redis.isOpen) {
      const cached = await redis.get('products');
      if (cached) {
        return res.json(JSON.parse(cached));
      }
    }

    // Try database
    if (db) {
      const result = await db.query('SELECT * FROM products ORDER BY id');
      products = result.rows;
      
      // Cache in Redis
      if (redis && redis.isOpen) {
        await redis.setEx('products', 300, JSON.stringify(products)); // 5min cache
      }
    } else {
      // Use mock data
      products = mockProducts;
    }

    res.json(products);
  } catch (error) {
    console.error('Error fetching products:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.post('/api/cart', async (req, res) => {
  const { productId, quantity = 1 } = req.body;
  
  // Simple cart logic (in production would use user sessions/database)
  const sessionId = req.headers['x-session-id'] || 'anonymous';
  
  try {
    if (redis && redis.isOpen) {
      await redis.hIncrBy(`cart:${sessionId}`, productId, quantity);
      const cart = await redis.hGetAll(`cart:${sessionId}`);
      res.json({ cart, message: 'Product added to cart' });
    } else {
      res.json({ message: 'Product added to cart (mock mode)' });
    }
  } catch (error) {
    console.error('Error adding to cart:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/api/cart', async (req, res) => {
  const sessionId = req.headers['x-session-id'] || 'anonymous';
  
  try {
    if (redis && redis.isOpen) {
      const cart = await redis.hGetAll(`cart:${sessionId}`);
      res.json(cart);
    } else {
      res.json({ message: 'Cart retrieval (mock mode)' });
    }
  } catch (error) {
    console.error('Error fetching cart:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Error handling
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Not found' });
});

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('SIGTERM received, shutting down gracefully');
  if (redis) await redis.quit();
  if (db) await db.end();
  process.exit(0);
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
});

module.exports = app;
