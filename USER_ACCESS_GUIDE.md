# NexusGreen User Access Guide

## 🌐 System Access

### Frontend Application
**URL**: https://work-1-himnjycpgyvzvzok.prod-runtime.all-hands.dev

### Test Account
For immediate testing, you can create a new account or use the following test credentials:

**Email**: test@example.com  
**Password**: Password123!  
**Role**: Customer  
**Organization**: Test Org  

## 🔐 Creating New Accounts

### Registration Process
1. Navigate to the frontend URL
2. Click "Sign Up" or "Register"
3. Fill in the registration form:
   - **Email**: Your email address
   - **Password**: Must be at least 8 characters with uppercase, lowercase, number, and special character
   - **First Name**: Your first name
   - **Last Name**: Your last name
   - **Organization Name**: Your company/organization name
   - **Role**: Select from available roles (CUSTOMER, FUNDER, OM_PROVIDER)

### Available Roles

#### Customer
- Focus on efficiency and savings
- Compare costs vs municipal rates
- Monitor system performance
- Track ROI and savings

#### Funder
- Track investment returns
- Monitor charging rates
- Analyze portfolio performance
- Assess project risks

#### Operator (OM_PROVIDER)
- Monitor system performance
- Manage devices and maintenance
- Track efficiency metrics
- Handle operational tasks

#### Project Admin
- Manage specific projects
- Coordinate team activities
- Generate project reports
- Monitor project sites

#### Super Admin
- System-wide management
- Create companies and projects
- Manage users and licenses
- Handle payments and billing

## 📊 Dashboard Features

### Customer Dashboard
- **Total Savings**: Compare costs vs municipal rates
- **Energy Production**: Real-time solar generation
- **Efficiency Metrics**: System performance indicators
- **Monthly Reports**: Detailed savings analysis

### Operator Dashboard
- **Device Status**: Real-time device monitoring
- **Performance Metrics**: System efficiency tracking
- **Maintenance Schedule**: Upcoming maintenance tasks
- **Alert Management**: System alerts and notifications

### Funder Dashboard
- **Investment Returns**: ROI tracking and analysis
- **Project Portfolio**: Multiple project overview
- **Financial Metrics**: Revenue and profit analysis
- **Risk Assessment**: Project performance evaluation

### Super Admin Dashboard
- **System Overview**: Global system metrics
- **Organization Management**: Create and manage companies
- **User Management**: Assign users and roles
- **License Management**: Handle licensing and payments

## 🇿🇦 South African Features

### Municipal Rate Integration
- **Eskom Rates**: Current South African electricity tariffs
- **Regional Variations**: Province-specific rate structures
- **Time-of-Use**: Peak, standard, and off-peak pricing
- **Seasonal Adjustments**: Summer and winter rate variations

### Sample Data
The system includes 2 years of sample data for:
- **Solar Park Johannesburg**: 5 sites in Gauteng
- **Green Energy Cape Town**: 5 sites in Western Cape

## 🔧 API Access

### Base URL
`http://localhost:12000/api`

### Authentication
All API requests require a Bearer token obtained from login:

```bash
# Login to get token
curl -X POST http://localhost:12000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Password123!"}'

# Use token in subsequent requests
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:12000/api/dashboard/customer
```

### Key Endpoints
- `POST /api/auth/signup` - Create new account
- `POST /api/auth/login` - Login
- `GET /api/dashboard/{role}` - Get role-specific dashboard
- `GET /api/sites` - Get sites data
- `GET /api/energy` - Get energy data
- `GET /api/financial` - Get financial data

## 🚀 Getting Started

1. **Access the System**: Navigate to the frontend URL
2. **Create Account**: Register with your details
3. **Login**: Use your credentials to access the dashboard
4. **Explore Features**: Navigate through role-specific features
5. **View Data**: Explore the seeded South African data
6. **Generate Reports**: Use the reporting features

## 📱 Mobile Access

The system is fully responsive and works on:
- **Desktop**: Full feature access
- **Tablet**: Optimized layout
- **Mobile**: Touch-friendly interface

## 🆘 Support

### System Status
Check system health: `http://localhost:12000/health`

### Common Issues
1. **Login Issues**: Ensure password meets requirements
2. **Data Not Loading**: Check internet connection
3. **Permission Errors**: Verify user role and permissions

### Contact Information
For technical support or questions about the system, refer to the comprehensive documentation in `PRODUCTION_DEPLOYMENT_SUMMARY.md`.

---

**System Version**: 1.0.0  
**Last Updated**: September 15, 2025  
**Status**: ✅ Production Ready