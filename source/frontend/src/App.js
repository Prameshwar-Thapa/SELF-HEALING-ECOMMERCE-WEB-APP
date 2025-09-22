import React, { useState, useEffect } from 'react';
import './App.css';

function App() {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [stats, setStats] = useState({ totalProducts: 0, categories: 0 });

  useEffect(() => {
    fetchProducts();
  }, []);

  const fetchProducts = async () => {
    try {
      setLoading(true);
      const response = await fetch('/api/products');
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      
      const data = await response.json();
      setProducts(data.products || []);
      
      // Calculate stats
      const categories = [...new Set(data.products.map(p => p.category_name))];
      setStats({
        totalProducts: data.products.length,
        categories: categories.length
      });
      
      setError(null);
    } catch (err) {
      console.error('Error fetching products:', err);
      setError('Failed to load products. Please try again later.');
    } finally {
      setLoading(false);
    }
  };

  const addToCart = (product) => {
    alert(`Added "${product.name}" to cart!`);
  };

  if (loading) {
    return (
      <div className="container">
        <div className="loading">Loading products...</div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="container">
        <div className="error">
          <h3>Oops! Something went wrong</h3>
          <p>{error}</p>
          <button onClick={fetchProducts} className="add-to-cart-btn" style={{width: 'auto', marginTop: '1rem'}}>
            Try Again
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="container">
      <header className="header">
        <h1>🛒 E-commerce Store</h1>
        <p>Self-Healing Infrastructure Demo</p>
      </header>

      <div className="stats">
        <div className="stat-item">
          <div className="stat-number">{stats.totalProducts}</div>
          <div className="stat-label">Products</div>
        </div>
        <div className="stat-item">
          <div className="stat-number">{stats.categories}</div>
          <div className="stat-label">Categories</div>
        </div>
        <div className="stat-item">
          <div className="stat-number">⚡</div>
          <div className="stat-label">Auto-Scaling</div>
        </div>
      </div>

      <div className="products-grid">
        {products.map((product) => (
          <div key={product.id} className="product-card">
            <img 
              src={product.image_url} 
              alt={product.name}
              className="product-image"
              onError={(e) => {
                e.target.src = 'https://via.placeholder.com/300x200?text=Product+Image';
              }}
            />
            <div className="product-category">{product.category_name}</div>
            <h3 className="product-title">{product.name}</h3>
            <p className="product-description">{product.description}</p>
            <div className="product-price">${product.price}</div>
            <button 
              className="add-to-cart-btn"
              onClick={() => addToCart(product)}
            >
              Add to Cart
            </button>
          </div>
        ))}
      </div>

      {products.length === 0 && !loading && (
        <div className="error">
          <h3>No products found</h3>
          <p>The store appears to be empty.</p>
        </div>
      )}
    </div>
  );
}

export default App;
