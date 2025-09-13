# 🛠️ SolarNexus Development Guide

This guide provides comprehensive instructions for developing with the SolarNexus unified repository.

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Repository Setup](#repository-setup)
- [Development Environment](#development-environment)
- [Frontend Development](#frontend-development)
- [Backend Development](#backend-development)
- [Database Management](#database-management)
- [Docker Development](#docker-development)
- [Testing](#testing)
- [Code Quality](#code-quality)
- [Deployment](#deployment)
- [Troubleshooting](#troubleshooting)

## 🔧 Prerequisites

### Required Software

- **Node.js 20+** - JavaScript runtime
- **npm** - Package manager (comes with Node.js)
- **Docker & Docker Compose** - Containerization
- **Git** - Version control
- **PostgreSQL 15** (optional, for local development)
- **Redis 7** (optional, for local development)

### Development Tools (Recommended)

- **VS Code** with extensions:
  - TypeScript and JavaScript Language Features
  - Prisma
  - Tailwind CSS IntelliSense
  - Docker
  - GitLens
- **Postman** or **Insomnia** for API testing
- **pgAdmin** or **DBeaver** for database management

## 📁 Repository Setup

### 1. Clone the Repository

```bash
git clone https://github.com/Reshigan/SolarNexus.git
cd SolarNexus
```

### 2. Install Dependencies

**Frontend Dependencies:**
```bash
npm install
```

**Backend Dependencies:**
```bash
cd solarnexus-backend
npm install
cd ..
```

### 3. Environment Configuration

Create environment files:

```bash
# Copy example environment file
cp .env.example .env

# Backend environment
cp solarnexus-backend/.env.example solarnexus-backend/.env
```

Update the environment variables as needed.

## 🌐 Development Environment

### Option 1: Full Docker Environment (Recommended)

Start all services with Docker:

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Check service status
docker-compose ps
```

Services will be available at:
- Frontend: http://localhost/
- Backend API: http://localhost:3000/
- Database: localhost:5432
- Redis: localhost:6379

### Option 2: Hybrid Development

Start backend services with Docker, frontend locally:

```bash
# Start backend services only
./deploy/quick-backend-start.sh

# In another terminal, start frontend dev server
npm run dev
```

### Option 3: Local Development

Install and run services locally (advanced):

```bash
# Start PostgreSQL and Redis locally
# (Installation varies by OS)

# Start backend
cd solarnexus-backend
npm run dev

# In another terminal, start frontend
npm run dev
```

## 📱 Frontend Development

### Project Structure

```
src/
├── components/          # Reusable React components
│   ├── ui/             # Base UI components (shadcn/ui)
│   ├── layout/         # Layout components
│   ├── forms/          # Form components
│   └── charts/         # Chart components
├── pages/              # Page components
├── hooks/              # Custom React hooks
├── lib/                # Utility libraries
├── types/              # TypeScript type definitions
└── styles/             # CSS and styling files
```

### Development Commands

```bash
# Start development server with hot reload
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview

# Run linting
npm run lint

# Fix linting issues
npm run lint:fix

# Type checking
npm run type-check
```

### Adding New Components

1. **Create component file:**
```bash
# Using shadcn/ui components
npx shadcn-ui@latest add button

# Custom components
mkdir src/components/my-component
touch src/components/my-component/index.tsx
```

2. **Component template:**
```typescript
import React from 'react';

interface MyComponentProps {
  title: string;
  children?: React.ReactNode;
}

export const MyComponent: React.FC<MyComponentProps> = ({ title, children }) => {
  return (
    <div className="p-4">
      <h2 className="text-xl font-semibold">{title}</h2>
      {children}
    </div>
  );
};

export default MyComponent;
```

### Styling Guidelines

- Use **Tailwind CSS** for styling
- Follow **shadcn/ui** component patterns
- Use **CSS modules** for complex custom styles
- Maintain consistent spacing and color schemes

### State Management

- Use **React hooks** (useState, useEffect, useContext)
- **Custom hooks** for reusable logic
- **Context API** for global state
- **React Query** for server state (if implemented)

## 🔧 Backend Development

### Project Structure

```
solarnexus-backend/
├── src/
│   ├── controllers/     # API route controllers
│   ├── middleware/      # Express middleware
│   ├── routes/          # API route definitions
│   ├── services/        # Business logic services
│   ├── utils/           # Utility functions
│   └── app.js           # Express application setup
├── prisma/              # Database schema and migrations
└── tests/               # Test files
```

### Development Commands

```bash
cd solarnexus-backend

# Start development server with hot reload
npm run dev

# Build for production
npm run build

# Start production server
npm start

# Run tests
npm test

# Run tests with coverage
npm run test:coverage
```

### API Development

1. **Create new route:**
```javascript
// src/routes/example.js
const express = require('express');
const router = express.Router();
const exampleController = require('../controllers/exampleController');

router.get('/', exampleController.getAll);
router.post('/', exampleController.create);
router.get('/:id', exampleController.getById);
router.put('/:id', exampleController.update);
router.delete('/:id', exampleController.delete);

module.exports = router;
```

2. **Create controller:**
```javascript
// src/controllers/exampleController.js
const exampleService = require('../services/exampleService');

const getAll = async (req, res) => {
  try {
    const items = await exampleService.findAll();
    res.json(items);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

module.exports = { getAll };
```

3. **Create service:**
```javascript
// src/services/exampleService.js
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

const findAll = async () => {
  return await prisma.example.findMany();
};

module.exports = { findAll };
```

### Authentication & Authorization

- **JWT tokens** for authentication
- **Role-based access control** (RBAC)
- **Middleware** for route protection

Example protected route:
```javascript
const authMiddleware = require('../middleware/auth');
const roleMiddleware = require('../middleware/role');

router.get('/admin', 
  authMiddleware, 
  roleMiddleware(['admin']), 
  controller.adminOnly
);
```

## 🗄️ Database Management

### Prisma ORM

The project uses Prisma for database management.

### Common Commands

```bash
cd solarnexus-backend

# Generate Prisma client
npx prisma generate

# Create new migration
npx prisma migrate dev --name your_migration_name

# Deploy migrations to production
npx prisma migrate deploy

# Reset database (development only)
npx prisma migrate reset

# Seed database with sample data
npx prisma db seed

# Open Prisma Studio (database GUI)
npx prisma studio
```

### Schema Development

1. **Edit schema file:**
```prisma
// prisma/schema.prisma
model User {
  id        Int      @id @default(autoincrement())
  email     String   @unique
  name      String?
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}
```

2. **Create migration:**
```bash
npx prisma migrate dev --name add_user_model
```

3. **Update client:**
```bash
npx prisma generate
```

### Database Queries

```javascript
// Using Prisma Client
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// Find many
const users = await prisma.user.findMany({
  where: { active: true },
  include: { posts: true }
});

// Create
const user = await prisma.user.create({
  data: {
    email: 'user@example.com',
    name: 'John Doe'
  }
});

// Update
const updatedUser = await prisma.user.update({
  where: { id: 1 },
  data: { name: 'Jane Doe' }
});
```

## 🐳 Docker Development

### Docker Compose Services

The project includes several Docker services:

- **postgres** - PostgreSQL database
- **redis** - Redis cache
- **backend** - Node.js API server
- **frontend** - React application (production build)
- **nginx** - Reverse proxy and static file server

### Development Commands

```bash
# Start all services
docker-compose up -d

# Start specific services
docker-compose up -d postgres redis backend

# View logs
docker-compose logs -f backend

# Execute commands in containers
docker-compose exec backend npm run migrate
docker-compose exec postgres psql -U solarnexus -d solarnexus

# Rebuild services
docker-compose up -d --build

# Stop all services
docker-compose down

# Remove volumes (careful!)
docker-compose down -v
```

### Custom Docker Commands

```bash
# Build only backend
docker-compose build backend

# Scale services
docker-compose up -d --scale backend=3

# View service status
docker-compose ps

# View resource usage
docker stats
```

## 🧪 Testing

### Frontend Testing

```bash
# Run unit tests
npm test

# Run tests in watch mode
npm run test:watch

# Run tests with coverage
npm run test:coverage

# Run e2e tests (if configured)
npm run test:e2e
```

### Backend Testing

```bash
cd solarnexus-backend

# Run unit tests
npm test

# Run integration tests
npm run test:integration

# Run API tests
npm run test:api

# Run all tests with coverage
npm run test:coverage
```

### Test Structure

```javascript
// Example test file
describe('User Service', () => {
  beforeEach(async () => {
    // Setup test database
  });

  afterEach(async () => {
    // Cleanup
  });

  it('should create a new user', async () => {
    const userData = { email: 'test@example.com', name: 'Test User' };
    const user = await userService.create(userData);
    
    expect(user).toBeDefined();
    expect(user.email).toBe(userData.email);
  });
});
```

## ✅ Code Quality

### Linting and Formatting

**Frontend:**
```bash
# Run ESLint
npm run lint

# Fix linting issues
npm run lint:fix

# Format with Prettier
npm run format
```

**Backend:**
```bash
cd solarnexus-backend

# Run ESLint
npm run lint

# Fix linting issues
npm run lint:fix
```

### Pre-commit Hooks

The project uses Husky for pre-commit hooks:

```bash
# Install Husky
npm install --save-dev husky

# Setup pre-commit hook
npx husky add .husky/pre-commit "npm run lint && npm test"
```

### Code Standards

- **TypeScript** for type safety
- **ESLint** for code linting
- **Prettier** for code formatting
- **Conventional Commits** for commit messages
- **JSDoc** for function documentation

## 🚀 Deployment

### Development Deployment

```bash
# Quick backend services
./deploy/quick-backend-start.sh

# Full development environment
docker-compose up -d
```

### Production Deployment

```bash
# Complete production setup
sudo ./deploy/clean-install.sh

# Manual production deployment
docker-compose -f docker-compose.prod.yml up -d
```

### Environment Variables

**Production Environment (.env):**
```env
NODE_ENV=production
DATABASE_URL=postgresql://user:pass@localhost:5432/solarnexus
REDIS_URL=redis://localhost:6379
JWT_SECRET=your_secure_jwt_secret
API_PORT=3000
```

### Health Checks

Monitor application health:

```bash
# Backend health check
curl http://localhost:3000/health

# Database connection test
docker-compose exec backend npm run db:test

# Service status
docker-compose ps
```

## 🔍 Troubleshooting

### Common Issues

**1. Port conflicts:**
```bash
# Check what's using port 3000
lsof -i :3000

# Kill process
kill -9 <PID>
```

**2. Database connection issues:**
```bash
# Check PostgreSQL status
docker-compose logs postgres

# Test database connection
docker-compose exec postgres pg_isready -U solarnexus
```

**3. Node modules issues:**
```bash
# Clear npm cache
npm cache clean --force

# Remove node_modules and reinstall
rm -rf node_modules package-lock.json
npm install
```

**4. Docker issues:**
```bash
# Restart Docker daemon
sudo systemctl restart docker

# Clean Docker system
docker system prune -a

# Remove all containers and volumes
docker-compose down -v
```

### Debug Mode

**Frontend Debug:**
```bash
# Start with debug logging
DEBUG=* npm run dev

# React DevTools
# Install React Developer Tools browser extension
```

**Backend Debug:**
```bash
cd solarnexus-backend

# Start with debug logging
DEBUG=* npm run dev

# Node.js inspector
node --inspect src/app.js
```

### Performance Monitoring

```bash
# Monitor Docker resources
docker stats

# Monitor application logs
docker-compose logs -f --tail=100

# Database performance
docker-compose exec postgres pg_stat_activity
```

## 📚 Additional Resources

- **[PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)** - Repository structure
- **[DEPLOYMENT_INSTRUCTIONS.md](DEPLOYMENT_INSTRUCTIONS.md)** - Deployment guide
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Common issues
- **[Prisma Documentation](https://www.prisma.io/docs/)**
- **[React Documentation](https://react.dev/)**
- **[Express.js Documentation](https://expressjs.com/)**
- **[Docker Documentation](https://docs.docker.com/)**

## 🤝 Contributing

1. **Fork the repository**
2. **Create a feature branch:** `git checkout -b feature/amazing-feature`
3. **Make your changes**
4. **Add tests** if applicable
5. **Commit your changes:** `git commit -m 'Add amazing feature'`
6. **Push to the branch:** `git push origin feature/amazing-feature`
7. **Open a Pull Request**

### Commit Message Format

Use conventional commits:
```
feat: add user authentication
fix: resolve database connection issue
docs: update development guide
style: format code with prettier
refactor: restructure user service
test: add unit tests for auth service
```

---

**Happy coding! 🚀**