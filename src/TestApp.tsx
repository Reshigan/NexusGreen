import React from 'react';

const TestApp = () => {
  return (
    <div style={{ 
      padding: '20px', 
      fontFamily: 'Arial, sans-serif',
      backgroundColor: '#f0f9ff',
      minHeight: '100vh',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      flexDirection: 'column'
    }}>
      <h1 style={{ color: '#10B981', marginBottom: '20px' }}>
        🌱 NexusGreen Test Page
      </h1>
      <p style={{ color: '#374151', fontSize: '18px', textAlign: 'center' }}>
        React is working! This is a test page to verify the application loads correctly.
      </p>
      <div style={{ 
        marginTop: '20px', 
        padding: '10px 20px', 
        backgroundColor: '#10B981', 
        color: 'white', 
        borderRadius: '8px' 
      }}>
        ✅ Frontend is operational
      </div>
    </div>
  );
};

export default TestApp;