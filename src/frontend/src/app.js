import React, { useState, useEffect } from 'react';
import axios from 'axios';

function App() {
  const [products, setProducts] = useState([]);
  const [cart, setCart] = useState([]);
  const [health, setHealth] = useState('unknown');

  useEffect(() => {
    // Fetch products
    axios.get('/api/products')
      .then(res => setProducts(res.data))
      .catch(err => console.error(err));
    
    // Check health
    axios.get('/health')
      .then(() => setHealth('healthy'))
      .catch(() => setHealth('unhealthy'));
  }, []);

  const addToCart = (product) => {
    setCart([...cart, product]);
  };

  return (
    <div className="App">
      <header style={{padding: '20px', background: '#f0f0f0'}}>
        <h1>DevOps E-commerce Test</h1>
        <div>Health: {health} | Cart: {cart.length} items</div>
      </header>
      
      <main style={{padding: '20px'}}>
        <h2>Products</h2>
        <div style={{display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(200px, 1fr))', gap: '20px'}}>
          {products.map(product => (
            <div key={product.id} style={{border: '1px solid #ccc', padding: '10px', borderRadius: '5px'}}>
              <h3>{product.name}</h3>
              <p>${product.price}</p>
              <button onClick={() => addToCart(product)}>Add to Cart</button>
            </div>
          ))}
        </div>
        
        {cart.length > 0 && (
          <div style={{marginTop: '30px', padding: '20px', background: '#e8f4f8', borderRadius: '5px'}}>
            <h3>Shopping Cart</h3>
            {cart.map((item, index) => (
              <div key={index}>{item.name} - ${item.price}</div>
            ))}
            <div><strong>Total: ${cart.reduce((sum, item) => sum + item.price, 0)}</strong></div>
          </div>
        )}
      </main>
    </div>
  );
}

export default App;
