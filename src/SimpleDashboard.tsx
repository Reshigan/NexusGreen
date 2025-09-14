import React, { useState, useEffect } from 'react';

const SimpleDashboard = () => {
  const [currentTime, setCurrentTime] = useState(new Date());
  const [metrics, setMetrics] = useState({
    totalGeneration: 2847.6,
    activeSites: 10,
    performance: 96.8,
    revenue: 125680.50,
    co2Saved: 1247.8
  });

  useEffect(() => {
    const timer = setInterval(() => {
      setCurrentTime(new Date());
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  const formatCurrency = (num: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }).format(num);
  };

  const MetricCard = ({ title, value, icon, color }: any) => (
    <div style={{
      background: 'white',
      borderRadius: '12px',
      padding: '24px',
      boxShadow: '0 4px 6px rgba(0, 0, 0, 0.1)',
      border: `3px solid ${color}`,
      transition: 'transform 0.2s ease',
      cursor: 'pointer'
    }}
    onMouseEnter={(e) => e.currentTarget.style.transform = 'translateY(-2px)'}
    onMouseLeave={(e) => e.currentTarget.style.transform = 'translateY(0px)'}
    >
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div>
          <h3 style={{ margin: '0 0 8px 0', color: '#374151', fontSize: '14px', fontWeight: '500' }}>
            {title}
          </h3>
          <p style={{ margin: 0, fontSize: '24px', fontWeight: 'bold', color: '#111827' }}>
            {value}
          </p>
        </div>
        <div style={{
          width: '48px',
          height: '48px',
          borderRadius: '12px',
          background: color,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          fontSize: '24px'
        }}>
          {icon}
        </div>
      </div>
    </div>
  );

  return (
    <div style={{
      minHeight: '100vh',
      background: 'linear-gradient(135deg, #f0f9ff 0%, #e0f2fe 50%, #f0fdf4 100%)',
      padding: '20px'
    }}>
      {/* Header */}
      <div style={{
        background: 'white',
        borderRadius: '16px',
        padding: '24px',
        marginBottom: '24px',
        boxShadow: '0 4px 6px rgba(0, 0, 0, 0.1)',
        border: '3px solid #10B981'
      }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
            <div style={{
              width: '48px',
              height: '48px',
              borderRadius: '12px',
              background: 'linear-gradient(135deg, #10B981, #059669)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: 'white',
              fontSize: '24px',
              fontWeight: 'bold'
            }}>
              N
            </div>
            <div>
              <h1 style={{ 
                margin: 0, 
                fontSize: '28px', 
                fontWeight: 'bold',
                background: 'linear-gradient(135deg, #10B981, #059669)',
                WebkitBackgroundClip: 'text',
                WebkitTextFillColor: 'transparent',
                backgroundClip: 'text'
              }}>
                NexusGreen Dashboard
              </h1>
              <p style={{ margin: '4px 0 0 0', color: '#6B7280', fontSize: '14px' }}>
                Solar Energy Management Platform
              </p>
            </div>
          </div>
          <div style={{ textAlign: 'right' }}>
            <p style={{ margin: 0, fontSize: '14px', color: '#6B7280' }}>
              Last Updated
            </p>
            <p style={{ margin: '4px 0 0 0', fontSize: '16px', fontWeight: '600', color: '#111827' }}>
              {currentTime.toLocaleTimeString()}
            </p>
          </div>
        </div>
      </div>

      {/* Metrics Grid */}
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))',
        gap: '24px',
        marginBottom: '24px'
      }}>
        <MetricCard
          title="Total Generation Today"
          value={`${metrics.totalGeneration.toLocaleString()} kWh`}
          icon="☀️"
          color="#F59E0B"
        />
        <MetricCard
          title="Revenue Today"
          value={formatCurrency(metrics.revenue)}
          icon="💰"
          color="#10B981"
        />
        <MetricCard
          title="System Performance"
          value={`${metrics.performance}%`}
          icon="⚡"
          color="#3B82F6"
        />
        <MetricCard
          title="CO₂ Saved"
          value={`${metrics.co2Saved.toLocaleString()} kg`}
          icon="🌱"
          color="#059669"
        />
      </div>

      {/* Sites Overview */}
      <div style={{
        background: 'white',
        borderRadius: '16px',
        padding: '24px',
        boxShadow: '0 4px 6px rgba(0, 0, 0, 0.1)',
        border: '3px solid #3B82F6'
      }}>
        <h2 style={{ 
          margin: '0 0 20px 0', 
          fontSize: '20px', 
          fontWeight: 'bold',
          color: '#111827'
        }}>
          🏢 Active Solar Installations
        </h2>
        
        <div style={{ display: 'grid', gap: '16px' }}>
          {[
            { name: 'Bay Area Corporate Campus', location: 'Palo Alto, CA', status: '✅ Optimal', generation: '2,187 kWh' },
            { name: 'LAX Cargo Terminal Solar', location: 'Los Angeles, CA', status: '⚠️ Warning', generation: '3,825 kWh' },
            { name: 'Phoenix Sky Harbor Solar Farm', location: 'Phoenix, AZ', status: '✅ Optimal', generation: '4,888 kWh' }
          ].map((site, index) => (
            <div key={index} style={{
              background: '#F9FAFB',
              borderRadius: '12px',
              padding: '20px',
              border: '2px solid #E5E7EB',
              transition: 'all 0.2s ease'
            }}
            onMouseEnter={(e) => {
              e.currentTarget.style.background = '#F3F4F6';
              e.currentTarget.style.borderColor = '#10B981';
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.background = '#F9FAFB';
              e.currentTarget.style.borderColor = '#E5E7EB';
            }}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div>
                  <h3 style={{ margin: '0 0 4px 0', fontSize: '16px', fontWeight: '600', color: '#111827' }}>
                    {site.name}
                  </h3>
                  <p style={{ margin: '0 0 8px 0', fontSize: '14px', color: '#6B7280' }}>
                    📍 {site.location}
                  </p>
                  <p style={{ margin: 0, fontSize: '14px', fontWeight: '500' }}>
                    {site.status}
                  </p>
                </div>
                <div style={{ textAlign: 'right' }}>
                  <p style={{ margin: '0 0 4px 0', fontSize: '14px', color: '#6B7280' }}>
                    Current Generation
                  </p>
                  <p style={{ margin: 0, fontSize: '18px', fontWeight: 'bold', color: '#10B981' }}>
                    {site.generation}
                  </p>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Footer */}
      <div style={{
        textAlign: 'center',
        marginTop: '40px',
        padding: '20px',
        color: '#6B7280'
      }}>
        <p style={{ margin: 0, fontSize: '14px' }}>
          🌞 NexusGreen v6.0.0 - Professional Solar Energy Management Platform
        </p>
        <p style={{ margin: '8px 0 0 0', fontSize: '12px' }}>
          Real-time monitoring • Advanced analytics • Sustainable energy solutions
        </p>
      </div>
    </div>
  );
};

export default SimpleDashboard;