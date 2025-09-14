# SolarNexus - User Guide

## Table of Contents
1. [Getting Started](#getting-started)
2. [Dashboard Overview](#dashboard-overview)
3. [Site Management](#site-management)
4. [Energy Monitoring](#energy-monitoring)
5. [Analytics and Reports](#analytics-and-reports)
6. [Alerts and Notifications](#alerts-and-notifications)
7. [User Management](#user-management)
8. [Settings and Configuration](#settings-and-configuration)
9. [Mobile Access](#mobile-access)
10. [Troubleshooting](#troubleshooting)

## Getting Started

### System Requirements
- **Web Browser**: Chrome 90+, Firefox 88+, Safari 14+, Edge 90+
- **Internet Connection**: Broadband connection recommended
- **Screen Resolution**: Minimum 1024x768, optimized for 1920x1080
- **JavaScript**: Must be enabled

### Accessing SolarNexus
1. Open your web browser
2. Navigate to: https://nexus.gonxt.tech
3. Enter your login credentials
4. Click "Sign In"

### First Time Login
1. **Welcome Email**: Check your email for welcome message with temporary password
2. **Password Reset**: You'll be prompted to change your password on first login
3. **Profile Setup**: Complete your profile information
4. **Organization Verification**: Verify your organization association

### User Roles and Permissions

#### Administrator
- Full system access
- User management
- Organization management
- System configuration
- All reporting features

#### Manager
- Organization-level access
- Site management within organization
- User management within organization
- Advanced reporting
- Alert configuration

#### User
- Site-level access
- Energy monitoring
- Basic reporting
- Alert viewing
- Profile management

#### Viewer
- Read-only access
- Energy monitoring
- Basic reports
- Dashboard viewing

## Dashboard Overview

### Main Dashboard Components

#### Summary Cards
- **Total Generation**: Current day/month/year energy production
- **Active Sites**: Number of operational sites
- **System Performance**: Overall efficiency percentage
- **Active Alerts**: Number of unresolved alerts

#### Real-Time Energy Chart
- Live energy generation data
- 24-hour generation curve
- Weather overlay
- Performance indicators

#### Site Status Grid
- Visual site status indicators
- Quick performance metrics
- Alert status per site
- Last update timestamps

#### Recent Activity Feed
- Latest system events
- Alert notifications
- Maintenance activities
- User actions

### Customizing Your Dashboard

#### Widget Configuration
1. Click the "Customize" button in the top right
2. Drag and drop widgets to rearrange
3. Click widget settings (gear icon) to configure
4. Save your layout preferences

#### Time Range Selection
- **Real-time**: Live data updates
- **Today**: Current day data
- **This Week**: 7-day view
- **This Month**: Monthly overview
- **Custom Range**: Select specific dates

#### Filtering Options
- **By Organization**: Filter data by organization
- **By Site**: Focus on specific sites
- **By Performance**: Show only high/low performers
- **By Alert Status**: Filter by alert conditions

## Site Management

### Adding a New Site

#### Basic Information
1. Navigate to "Sites" → "Add New Site"
2. Enter site details:
   - **Site Name**: Descriptive name for the installation
   - **Location**: Address or GPS coordinates
   - **Capacity**: System capacity in kW
   - **Installation Date**: When the system was commissioned

#### SolaX Integration
1. **API Credentials**: Enter SolaX Cloud credentials
   - Client ID
   - Client Secret
   - Plant ID
2. **Test Connection**: Verify API connectivity
3. **Data Sync**: Configure data synchronization frequency

#### Site Configuration
1. **Tariff Settings**: Configure electricity tariffs
2. **Performance Targets**: Set expected performance benchmarks
3. **Alert Thresholds**: Define alert trigger conditions
4. **Maintenance Schedule**: Set up maintenance reminders

### Managing Existing Sites

#### Site Overview
- **Performance Summary**: Key performance indicators
- **System Information**: Technical specifications
- **Recent Data**: Latest energy production data
- **Alert History**: Past and current alerts

#### Editing Site Information
1. Click on site name or "Edit" button
2. Modify required fields
3. Update SolaX credentials if needed
4. Save changes

#### Site Status Management
- **Active**: Site is operational and monitored
- **Inactive**: Site is temporarily disabled
- **Maintenance**: Site is under maintenance
- **Decommissioned**: Site is permanently offline

### Bulk Operations
1. Select multiple sites using checkboxes
2. Choose bulk action:
   - Update tariff settings
   - Change alert thresholds
   - Export site data
   - Generate reports

## Energy Monitoring

### Real-Time Monitoring

#### Live Energy Data
- **Current Generation**: Real-time power output
- **Daily Production**: Cumulative daily energy
- **Grid Import/Export**: Energy flow to/from grid
- **Battery Status**: Charge level and flow (if applicable)

#### Performance Indicators
- **Efficiency**: Current system efficiency
- **Capacity Factor**: Percentage of rated capacity
- **Performance Ratio**: Actual vs. expected performance
- **Availability**: System uptime percentage

### Historical Data Analysis

#### Time Series Charts
1. **Select Time Range**: Choose analysis period
2. **Choose Metrics**: Select data points to display
3. **Compare Periods**: Overlay different time periods
4. **Export Data**: Download data for external analysis

#### Data Granularity
- **5-minute intervals**: Detailed analysis
- **Hourly data**: Daily pattern analysis
- **Daily summaries**: Long-term trends
- **Monthly aggregates**: Seasonal analysis

### Weather Correlation
- **Solar Irradiance**: Correlation with generation
- **Temperature**: Impact on system efficiency
- **Cloud Cover**: Effect on production variability
- **Weather Forecast**: Predicted generation impact

### Performance Benchmarking
- **Expected vs. Actual**: Performance comparison
- **Peer Comparison**: Compare with similar sites
- **Historical Trends**: Long-term performance analysis
- **Degradation Analysis**: System aging assessment

## Analytics and Reports

### Performance Analytics

#### System Performance Report
- **Generation Summary**: Total energy produced
- **Efficiency Analysis**: System efficiency trends
- **Availability Report**: Uptime and downtime analysis
- **Performance Ratio**: Actual vs. theoretical performance

#### Financial Analytics
- **Revenue Tracking**: Income from energy sales
- **Cost Analysis**: Operational and maintenance costs
- **Savings Calculation**: Energy cost savings
- **ROI Analysis**: Return on investment metrics

### Predictive Analytics

#### Generation Forecasting
- **Short-term Forecast**: Next 7 days prediction
- **Weather-based Prediction**: Weather-adjusted forecasts
- **Seasonal Projections**: Long-term generation estimates
- **Confidence Intervals**: Prediction accuracy ranges

#### Maintenance Predictions
- **Equipment Health**: Component condition assessment
- **Failure Predictions**: Potential equipment failures
- **Maintenance Scheduling**: Optimal maintenance timing
- **Cost Optimization**: Maintenance cost predictions

### Custom Reports

#### Report Builder
1. **Select Report Type**: Choose from templates
2. **Configure Parameters**: Set date ranges and filters
3. **Choose Metrics**: Select data points to include
4. **Format Options**: PDF, Excel, or online view
5. **Schedule Reports**: Automate report generation

#### Available Report Types
- **Daily Performance**: Daily generation summary
- **Monthly Summary**: Monthly performance overview
- **Annual Report**: Yearly performance analysis
- **Financial Report**: Revenue and cost analysis
- **Sustainability Report**: Environmental impact
- **Maintenance Report**: Maintenance activities and costs

### Data Export
- **CSV Format**: Raw data for analysis
- **Excel Format**: Formatted spreadsheets
- **PDF Reports**: Professional formatted reports
- **API Access**: Programmatic data access

## Alerts and Notifications

### Alert Types

#### Performance Alerts
- **Low Generation**: Below expected production
- **Efficiency Drop**: Significant efficiency decrease
- **System Offline**: Communication loss
- **Performance Degradation**: Long-term decline

#### Equipment Alerts
- **Inverter Fault**: Inverter malfunction
- **String Failure**: DC string issues
- **Communication Error**: Data transmission problems
- **Temperature Alert**: Overheating conditions

#### Financial Alerts
- **Revenue Drop**: Significant income decrease
- **High Costs**: Unexpected cost increases
- **Tariff Changes**: Electricity rate modifications
- **Budget Exceeded**: Cost overruns

### Alert Configuration

#### Setting Alert Thresholds
1. Navigate to "Settings" → "Alerts"
2. Select alert type
3. Configure threshold values
4. Set alert severity levels
5. Choose notification methods

#### Notification Preferences
- **Email Notifications**: Immediate email alerts
- **SMS Alerts**: Text message notifications (premium)
- **In-App Notifications**: Dashboard notifications
- **Push Notifications**: Mobile app alerts

### Managing Alerts

#### Alert Dashboard
- **Active Alerts**: Current unresolved alerts
- **Alert History**: Past alert records
- **Alert Statistics**: Alert frequency analysis
- **Response Times**: Alert resolution metrics

#### Alert Actions
- **Acknowledge**: Mark alert as seen
- **Resolve**: Mark issue as fixed
- **Escalate**: Forward to higher authority
- **Add Notes**: Document actions taken

### Alert Automation
- **Auto-Acknowledgment**: Automatic alert acknowledgment
- **Escalation Rules**: Automatic escalation after time
- **Resolution Triggers**: Auto-resolve based on conditions
- **Notification Schedules**: Time-based notification rules

## User Management

### Profile Management

#### Personal Information
1. Click on your name/avatar in top right
2. Select "Profile Settings"
3. Update personal information:
   - Name and contact details
   - Email preferences
   - Language settings
   - Time zone configuration

#### Password Management
1. Navigate to "Security" tab
2. Click "Change Password"
3. Enter current password
4. Set new secure password
5. Confirm password change

#### Two-Factor Authentication
1. Go to "Security Settings"
2. Enable "Two-Factor Authentication"
3. Scan QR code with authenticator app
4. Enter verification code
5. Save backup codes securely

### Organization Users (Manager/Admin)

#### Adding New Users
1. Navigate to "Users" → "Add User"
2. Enter user information:
   - Email address
   - First and last name
   - Role assignment
   - Site access permissions
3. Send invitation email
4. User receives setup instructions

#### Managing User Permissions
- **Role Assignment**: Change user roles
- **Site Access**: Grant/revoke site access
- **Feature Permissions**: Control feature access
- **Temporary Access**: Set access expiration dates

#### User Activity Monitoring
- **Login History**: Track user login activity
- **Action Logs**: Monitor user actions
- **Access Reports**: Generate access reports
- **Security Events**: Monitor security-related events

## Settings and Configuration

### System Settings

#### General Configuration
- **Time Zone**: Set system time zone
- **Date Format**: Choose date display format
- **Number Format**: Configure number formatting
- **Language**: Select interface language

#### Data Settings
- **Update Frequency**: Configure data refresh rates
- **Data Retention**: Set data storage periods
- **Backup Settings**: Configure backup preferences
- **Export Formats**: Set default export formats

### Site Configuration

#### Performance Settings
- **Expected Performance**: Set performance benchmarks
- **Degradation Rate**: Configure degradation assumptions
- **Weather Adjustments**: Enable weather corrections
- **Seasonal Adjustments**: Account for seasonal variations

#### Financial Settings
- **Electricity Tariffs**: Configure tariff structures
- **Currency Settings**: Set local currency
- **Tax Rates**: Configure applicable tax rates
- **Cost Categories**: Define cost classifications

### Integration Settings

#### SolaX Cloud Integration
- **API Configuration**: Set API endpoints and credentials
- **Data Mapping**: Configure data field mapping
- **Sync Frequency**: Set synchronization intervals
- **Error Handling**: Configure error response actions

#### Third-Party Integrations
- **Weather Services**: Configure weather data sources
- **Email Services**: Set up email notifications
- **Export Services**: Configure data export destinations
- **Webhook Configuration**: Set up webhook endpoints

## Mobile Access

### Mobile Web Interface
- **Responsive Design**: Optimized for mobile browsers
- **Touch Navigation**: Touch-friendly interface
- **Offline Capability**: Limited offline functionality
- **Push Notifications**: Browser-based notifications

### Mobile App Features
- **Dashboard Access**: Mobile dashboard view
- **Real-time Monitoring**: Live energy data
- **Alert Notifications**: Push notifications
- **Quick Actions**: Common tasks on mobile

### Mobile Optimization Tips
- **Bookmark Site**: Add to home screen
- **Enable Notifications**: Allow browser notifications
- **Use WiFi**: For better performance
- **Update Browser**: Keep browser updated

## Troubleshooting

### Common Issues

#### Login Problems
**Issue**: Cannot log in to the system
**Solutions**:
1. Check username/email spelling
2. Reset password using "Forgot Password"
3. Clear browser cache and cookies
4. Try different browser
5. Contact system administrator

#### Data Not Updating
**Issue**: Energy data not showing recent updates
**Solutions**:
1. Check internet connection
2. Refresh browser page (F5)
3. Verify SolaX API credentials
4. Check site status in settings
5. Contact technical support

#### Performance Issues
**Issue**: Slow loading or unresponsive interface
**Solutions**:
1. Check internet connection speed
2. Close unnecessary browser tabs
3. Clear browser cache
4. Disable browser extensions
5. Try different browser

#### Chart Display Issues
**Issue**: Charts not displaying correctly
**Solutions**:
1. Enable JavaScript in browser
2. Update browser to latest version
3. Check browser compatibility
4. Disable ad blockers
5. Try incognito/private mode

### Browser Compatibility

#### Supported Browsers
- **Chrome**: Version 90 and later
- **Firefox**: Version 88 and later
- **Safari**: Version 14 and later
- **Edge**: Version 90 and later

#### Unsupported Browsers
- Internet Explorer (all versions)
- Chrome versions below 90
- Firefox versions below 88
- Safari versions below 14

### Getting Help

#### Self-Service Resources
- **Help Documentation**: Built-in help system
- **Video Tutorials**: Step-by-step guides
- **FAQ Section**: Common questions and answers
- **User Community**: User forum and discussions

#### Technical Support
- **Email Support**: support@solarnexus.com
- **Phone Support**: [Phone Number]
- **Live Chat**: Available during business hours
- **Remote Assistance**: Screen sharing support

#### Support Information to Provide
1. **User Information**: Name, email, organization
2. **Issue Description**: Detailed problem description
3. **Steps to Reproduce**: What actions led to the issue
4. **Browser Information**: Browser type and version
5. **Screenshots**: Visual evidence of the issue
6. **Error Messages**: Exact error text

### System Status
- **Status Page**: https://status.nexus.gonxt.tech
- **Maintenance Notifications**: Advance notice of maintenance
- **Service Updates**: System update announcements
- **Performance Metrics**: Real-time system performance

---

*This user guide is regularly updated to reflect new features and improvements. For the latest version, visit the help section within the application.*