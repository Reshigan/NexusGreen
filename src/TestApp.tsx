import React from 'react';

const TestApp = () => {
  return (
    <div style={{ 
      padding: '20px', 
      fontFamily: 'Arial, sans-serif',
      background: 'linear-gradient(135deg, #10B981, #059669)',
      minHeight: '100vh',
      color: 'white'
    }}>
      <h1>🌞 NexusGreen Test Page</h1>
      <p>If you can see this, React is working!</p>
      <div style={{ 
        background: 'rgba(255,255,255,0.1)', 
        padding: '20px', 
        borderRadius: '10px',
        marginTop: '20px'
      }}>
        <h2>✅ System Status</h2>
        <ul>
          <li>React: Working</li>
          <li>TypeScript: Working</li>
          <li>Build: Successful</li>
          <li>Routing: Testing...</li>
        </ul>
      </div>
      <div style={{ marginTop: '20px' }}>
        <button 
          onClick={() => window.location.href = '/dashboard'}
          style={{
            background: '#059669',
            color: 'white',
            border: 'none',
            padding: '10px 20px',
            borderRadius: '5px',
            cursor: 'pointer',
            fontSize: '16px'
          }}
        >
          Go to Dashboard
        </button>
      </div>
    </div>
  );
};

export default TestApp;