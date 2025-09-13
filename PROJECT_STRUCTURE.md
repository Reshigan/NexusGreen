# SolarNexus - Unified Repository Structure

This repository contains the complete SolarNexus application with both frontend and backend components in a single, unified codebase.

## 📁 Repository Structure

```
SolarNexus/
├── 📱 Frontend (React + TypeScript + Vite)
│   ├── src/                          # Frontend source code
│   │   ├── components/               # Reusable React components
│   │   │   ├── ui/                   # Base UI components (shadcn/ui)
│   │   │   ├── layout/               # Layout components
│   │   │   ├── forms/                # Form components
│   │   │   └── charts/               # Chart components
│   │   ├── pages/                    # Page components
│   │   │   ├── auth/                 # Authentication pages
│   │   │   ├── dashboard/            # Dashboard pages
│   │   │   ├── projects/             # Project management pages
│   │   │   ├── sites/                # Site management pages
│   │   │   └── reports/              # Reporting pages
│   │   ├── hooks/                    # Custom React hooks
│   │   ├── lib/                      # Utility libraries
│   │   ├── types/                    # TypeScript type definitions
│   │   ├── styles/                   # CSS and styling files
│   │   └── App.tsx                   # Main application component
│   ├── public/                       # Static assets
│   ├── index.html                    # HTML entry point
│   ├── package.json                  # Frontend dependencies
│   ├── vite.config.ts               # Vite configuration
│   ├── tailwind.config.ts           # Tailwind CSS configuration
│   ├── tsconfig.json                # TypeScript configuration
│   └── Dockerfile                   # Frontend Docker configuration
│
├── 🔧 Backend (Node.js + Express + Prisma)
│   └── solarnexus-backend/
│       ├── src/                      # Backend source code
│       │   ├── controllers/          # API route controllers
│       │   ├── middleware/           # Express middleware
│       │   ├── routes/               # API route definitions
│       │   ├── services/             # Business logic services
│       │   ├── utils/                # Utility functions
│       │   └── app.js                # Express application setup
│       ├── prisma/                   # Database schema and migrations
│       │   ├── schema.prisma         # Prisma database schema
│       │   └── migrations/           # Database migration files
│       ├── package.json              # Backend dependencies
│       ├── Dockerfile                # Backend Docker configuration
│       └── migration.sql             # Database initialization script
│
├── 🐳 Infrastructure & Deployment
│   ├── deploy/                       # Deployment scripts
│   │   ├── clean-install.sh          # Complete installation script
│   │   ├── quick-backend-start.sh    # Quick backend startup
│   │   └── docker-compose.*.yml      # Docker Compose configurations
│   ├── nginx/                        # Nginx configuration
│   │   └── conf.d/                   # Nginx server configurations
│   ├── database/                     # Database initialization
│   │   └── init/                     # Database init scripts
│   ├── docker-compose.yml            # Main Docker Compose file
│   ├── nginx.conf                    # Nginx configuration
│   └── ssl/                          # SSL certificates (production)
│
├── 📚 Documentation
│   ├── README.md                     # Main project documentation
│   ├── PROJECT_STRUCTURE.md          # This file
│   ├── DEPLOYMENT_INSTRUCTIONS.md    # Deployment guide
│   ├── DEVELOPMENT_GUIDE.md          # Development setup guide
│   ├── SYSTEM_DESIGN.md              # System architecture
│   └── TROUBLESHOOTING.md            # Common issues and solutions
│
├── 📊 Data & Logs
│   ├── uploads/                      # File uploads directory
│   └── logs/                         # Application logs
│
└── ⚙️ Configuration
    ├── .env                          # Environment variables
    ├── .gitignore                    # Git ignore rules
    ├── components.json               # shadcn/ui configuration
    ├── eslint.config.js              # ESLint configuration
    ├── postcss.config.js             # PostCSS configuration
    └── bun.lockb                     # Package lock file
```

## 🏗️ Architecture Overview

### Frontend Architecture
- **Framework**: React 18 with TypeScript
- **Build Tool**: Vite for fast development and building
- **Styling**: Tailwind CSS with shadcn/ui components
- **State Management**: React hooks and context
- **Routing**: React Router for navigation
- **Charts**: Recharts for data visualization
- **HTTP Client**: Axios for API communication

### Backend Architecture
- **Runtime**: Node.js with Express.js framework
- **Database**: PostgreSQL with Prisma ORM
- **Cache**: Redis for session and data caching
- **Authentication**: JWT-based authentication
- **API**: RESTful API with JSON responses
- **File Handling**: Multer for file uploads

### Infrastructure
- **Containerization**: Docker and Docker Compose
- **Reverse Proxy**: Nginx for routing and static file serving
- **Database**: PostgreSQL 15 with persistent volumes
- **Cache**: Redis 7 with persistent storage
- **SSL**: Let's Encrypt certificates (production)

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose
- Node.js 20+ (for local development)
- Git

### Production Deployment
```bash
# Clone the repository
git clone https://github.com/Reshigan/SolarNexus.git
cd SolarNexus

# Run the complete installation
sudo ./deploy/clean-install.sh
```

### Development Setup
```bash
# Clone the repository
git clone https://github.com/Reshigan/SolarNexus.git
cd SolarNexus

# Start backend services only
./deploy/quick-backend-start.sh

# In another terminal, start frontend development server
npm install
npm run dev
```

## 🔧 Development Workflow

### Frontend Development
```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview

# Run linting
npm run lint
```

### Backend Development
```bash
cd solarnexus-backend

# Install dependencies
npm install

# Run database migrations
npx prisma migrate dev

# Generate Prisma client
npx prisma generate

# Start development server
npm run dev

# View database
npx prisma studio
```

### Full Stack Development
```bash
# Start all services with Docker Compose
docker-compose up -d

# View logs
docker-compose logs -f

# Stop all services
docker-compose down
```

## 📦 Package Management

### Frontend Dependencies
- **React**: UI framework
- **TypeScript**: Type safety
- **Vite**: Build tool and dev server
- **Tailwind CSS**: Utility-first CSS framework
- **shadcn/ui**: Component library
- **React Router**: Client-side routing
- **Recharts**: Chart library
- **Axios**: HTTP client
- **React Hook Form**: Form handling
- **Zod**: Schema validation

### Backend Dependencies
- **Express**: Web framework
- **Prisma**: Database ORM
- **JWT**: Authentication tokens
- **bcrypt**: Password hashing
- **multer**: File upload handling
- **cors**: Cross-origin resource sharing
- **helmet**: Security middleware
- **winston**: Logging

## 🗄️ Database Schema

The database schema is defined in `solarnexus-backend/prisma/schema.prisma` and includes:

- **Users**: User accounts and authentication
- **Organizations**: Multi-tenant organization support
- **Projects**: Solar installation projects
- **Sites**: Physical installation sites
- **Devices**: Solar equipment and sensors
- **Energy Data**: Real-time energy generation and consumption
- **Financial Data**: Cost savings and revenue tracking
- **Performance Metrics**: System performance analytics

## 🔐 Environment Configuration

Key environment variables:
- `NODE_ENV`: Environment (development/production)
- `DATABASE_URL`: PostgreSQL connection string
- `REDIS_URL`: Redis connection string
- `JWT_SECRET`: JWT signing secret
- `API_PORT`: Backend server port
- `REACT_APP_API_URL`: Frontend API endpoint

## 🚢 Deployment Options

1. **Docker Compose** (Recommended)
   - Single command deployment
   - All services containerized
   - Production-ready configuration

2. **Manual Installation**
   - Individual service setup
   - Custom configuration
   - Advanced deployment scenarios

3. **Cloud Deployment**
   - AWS, GCP, Azure compatible
   - Kubernetes manifests available
   - CI/CD pipeline ready

## 🔍 Monitoring & Logging

- **Application Logs**: Winston logging framework
- **Nginx Logs**: Access and error logs
- **Database Logs**: PostgreSQL query logs
- **Container Logs**: Docker container logs
- **Health Checks**: Built-in health endpoints

## 🧪 Testing

### Frontend Testing
```bash
# Run unit tests
npm run test

# Run e2e tests
npm run test:e2e

# Coverage report
npm run test:coverage
```

### Backend Testing
```bash
cd solarnexus-backend

# Run unit tests
npm run test

# Run integration tests
npm run test:integration

# API testing
npm run test:api
```

## 📈 Performance Optimization

- **Frontend**: Code splitting, lazy loading, image optimization
- **Backend**: Database indexing, query optimization, caching
- **Infrastructure**: CDN, load balancing, horizontal scaling

## 🔒 Security Features

- JWT-based authentication
- Password hashing with bcrypt
- CORS protection
- Helmet security headers
- Input validation and sanitization
- SQL injection prevention
- XSS protection

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📞 Support

For issues and questions:
- Create an issue on GitHub
- Check the troubleshooting guide
- Review the documentation

---

**This unified repository serves as the single source of truth for the entire SolarNexus application.**