import { useState, useEffect } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { 
  Shield,
  Users,
  Building,
  CreditCard,
  Settings,
  Plus,
  Edit,
  Trash2,
  Eye,
  CheckCircle,
  XCircle,
  AlertTriangle,
  Crown,
  Zap,
  Globe
} from "lucide-react";
import DashboardLayout from "@/components/DashboardLayout";
import NexusGreenLogo from "@/components/NexusGreenLogo";

// Mock data for multi-tenant system
const mockTenants = [
  {
    id: 1,
    name: "Solar Solutions Inc",
    domain: "solarsolutions.nexusgreen.com",
    plan: "Enterprise",
    status: "active",
    users: 45,
    sites: 120,
    monthlyRevenue: 2500,
    createdAt: "2024-01-15",
    expiresAt: "2025-01-15"
  },
  {
    id: 2,
    name: "Green Energy Corp",
    domain: "greenenergy.nexusgreen.com", 
    plan: "Professional",
    status: "active",
    users: 23,
    sites: 67,
    monthlyRevenue: 1200,
    createdAt: "2024-02-20",
    expiresAt: "2024-12-20"
  },
  {
    id: 3,
    name: "EcoTech Systems",
    domain: "ecotech.nexusgreen.com",
    plan: "Starter",
    status: "trial",
    users: 8,
    sites: 15,
    monthlyRevenue: 0,
    createdAt: "2024-03-10",
    expiresAt: "2024-04-10"
  }
];

const mockLicenses = [
  {
    id: 1,
    type: "Enterprise",
    maxUsers: 100,
    maxSites: 500,
    features: ["Advanced Analytics", "API Access", "White Label", "Priority Support"],
    price: 2500,
    active: 12
  },
  {
    id: 2,
    type: "Professional", 
    maxUsers: 50,
    maxSites: 200,
    features: ["Standard Analytics", "Email Support", "Custom Reports"],
    price: 1200,
    active: 28
  },
  {
    id: 3,
    type: "Starter",
    maxUsers: 10,
    maxSites: 25,
    features: ["Basic Monitoring", "Standard Support"],
    price: 299,
    active: 45
  }
];

const SuperAdmin = () => {
  const [selectedTab, setSelectedTab] = useState("overview");
  const [tenants, setTenants] = useState(mockTenants);
  const [licenses, setLicenses] = useState(mockLicenses);

  const getStatusColor = (status: string) => {
    switch (status) {
      case "active": return "bg-green-100 text-green-800 border-green-200";
      case "trial": return "bg-blue-100 text-blue-800 border-blue-200";
      case "suspended": return "bg-red-100 text-red-800 border-red-200";
      case "expired": return "bg-gray-100 text-gray-800 border-gray-200";
      default: return "bg-gray-100 text-gray-800 border-gray-200";
    }
  };

  const getPlanColor = (plan: string) => {
    switch (plan) {
      case "Enterprise": return "bg-purple-100 text-purple-800 border-purple-200";
      case "Professional": return "bg-blue-100 text-blue-800 border-blue-200";
      case "Starter": return "bg-green-100 text-green-800 border-green-200";
      default: return "bg-gray-100 text-gray-800 border-gray-200";
    }
  };

  const totalRevenue = tenants.reduce((sum, tenant) => sum + tenant.monthlyRevenue, 0);
  const totalUsers = tenants.reduce((sum, tenant) => sum + tenant.users, 0);
  const totalSites = tenants.reduce((sum, tenant) => sum + tenant.sites, 0);

  return (
    <DashboardLayout>
      <div className="space-y-6">
        {/* Header */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <div className="flex items-center gap-4">
              <div className="relative">
                <Crown className="h-8 w-8 text-yellow-500" />
                <div className="absolute inset-0 bg-yellow-400 rounded-full blur-sm opacity-50"></div>
              </div>
              <div>
                <h1 className="text-3xl font-bold bg-gradient-to-r from-purple-600 via-pink-600 to-red-600 bg-clip-text text-transparent">
                  SuperAdmin Console
                </h1>
                <p className="text-muted-foreground font-medium">Multi-Tenant License Management</p>
              </div>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <Badge variant="outline" className="text-purple-600 border-purple-200">
              <Shield className="h-3 w-3 mr-1" />
              SuperAdmin Access
            </Badge>
            <Button className="bg-gradient-to-r from-purple-500 to-pink-500 hover:from-purple-600 hover:to-pink-600">
              <Plus className="h-4 w-4 mr-2" />
              New Tenant
            </Button>
          </div>
        </div>

        {/* Key Metrics */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          <Card className="relative overflow-hidden border-0 bg-gradient-to-br from-purple-50 via-pink-50 to-red-50 shadow-lg hover:shadow-xl transition-all duration-300 group">
            <div className="absolute inset-0 bg-gradient-to-br from-purple-400/10 via-pink-500/10 to-red-600/10"></div>
            <div className="absolute top-0 right-0 w-20 h-20 bg-gradient-to-br from-purple-400/20 to-pink-500/20 rounded-full -translate-y-10 translate-x-10 group-hover:scale-110 transition-transform duration-300"></div>
            <CardHeader className="relative flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-semibold text-gray-700">Total Tenants</CardTitle>
              <Building className="h-5 w-5 text-purple-600" />
            </CardHeader>
            <CardContent className="relative">
              <div className="text-3xl font-bold bg-gradient-to-r from-purple-600 to-pink-600 bg-clip-text text-transparent">
                {tenants.length}
              </div>
              <p className="text-xs text-purple-600 font-medium mt-1">
                {tenants.filter(t => t.status === 'active').length} active
              </p>
            </CardContent>
          </Card>

          <Card className="relative overflow-hidden border-0 bg-gradient-to-br from-green-50 via-emerald-50 to-teal-50 shadow-lg hover:shadow-xl transition-all duration-300 group">
            <div className="absolute inset-0 bg-gradient-to-br from-green-400/10 via-emerald-500/10 to-teal-600/10"></div>
            <div className="absolute top-0 right-0 w-20 h-20 bg-gradient-to-br from-green-400/20 to-emerald-500/20 rounded-full -translate-y-10 translate-x-10 group-hover:scale-110 transition-transform duration-300"></div>
            <CardHeader className="relative flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-semibold text-gray-700">Monthly Revenue</CardTitle>
              <CreditCard className="h-5 w-5 text-green-600" />
            </CardHeader>
            <CardContent className="relative">
              <div className="text-3xl font-bold bg-gradient-to-r from-green-600 to-emerald-600 bg-clip-text text-transparent">
                ${totalRevenue.toLocaleString()}
              </div>
              <p className="text-xs text-green-600 font-medium mt-1">
                +15.3% from last month
              </p>
            </CardContent>
          </Card>

          <Card className="relative overflow-hidden border-0 bg-gradient-to-br from-blue-50 via-cyan-50 to-sky-50 shadow-lg hover:shadow-xl transition-all duration-300 group">
            <div className="absolute inset-0 bg-gradient-to-br from-blue-400/10 via-cyan-500/10 to-sky-600/10"></div>
            <div className="absolute top-0 right-0 w-20 h-20 bg-gradient-to-br from-blue-400/20 to-cyan-500/20 rounded-full -translate-y-10 translate-x-10 group-hover:scale-110 transition-transform duration-300"></div>
            <CardHeader className="relative flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-semibold text-gray-700">Total Users</CardTitle>
              <Users className="h-5 w-5 text-blue-600" />
            </CardHeader>
            <CardContent className="relative">
              <div className="text-3xl font-bold bg-gradient-to-r from-blue-600 to-cyan-600 bg-clip-text text-transparent">
                {totalUsers.toLocaleString()}
              </div>
              <p className="text-xs text-blue-600 font-medium mt-1">
                Across all tenants
              </p>
            </CardContent>
          </Card>

          <Card className="relative overflow-hidden border-0 bg-gradient-to-br from-amber-50 via-yellow-50 to-orange-50 shadow-lg hover:shadow-xl transition-all duration-300 group">
            <div className="absolute inset-0 bg-gradient-to-br from-amber-400/10 via-yellow-500/10 to-orange-600/10"></div>
            <div className="absolute top-0 right-0 w-20 h-20 bg-gradient-to-br from-amber-400/20 to-yellow-500/20 rounded-full -translate-y-10 translate-x-10 group-hover:scale-110 transition-transform duration-300"></div>
            <CardHeader className="relative flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-semibold text-gray-700">Total Sites</CardTitle>
              <Zap className="h-5 w-5 text-amber-600" />
            </CardHeader>
            <CardContent className="relative">
              <div className="text-3xl font-bold bg-gradient-to-r from-amber-600 to-yellow-600 bg-clip-text text-transparent">
                {totalSites.toLocaleString()}
              </div>
              <p className="text-xs text-amber-600 font-medium mt-1">
                Solar installations
              </p>
            </CardContent>
          </Card>
        </div>

        {/* Main Content */}
        <Tabs value={selectedTab} onValueChange={setSelectedTab} className="space-y-4">
          <TabsList className="grid w-full grid-cols-3">
            <TabsTrigger value="overview">Overview</TabsTrigger>
            <TabsTrigger value="tenants">Tenant Management</TabsTrigger>
            <TabsTrigger value="licenses">License Management</TabsTrigger>
          </TabsList>

          <TabsContent value="overview" className="space-y-6">
            {/* System Status */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Globe className="h-5 w-5" />
                  System Status
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <div className="flex items-center gap-3 p-4 bg-green-50 rounded-lg border border-green-200">
                    <CheckCircle className="h-5 w-5 text-green-600" />
                    <div>
                      <p className="font-semibold text-green-800">System Healthy</p>
                      <p className="text-xs text-green-600">All services operational</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-3 p-4 bg-blue-50 rounded-lg border border-blue-200">
                    <Zap className="h-5 w-5 text-blue-600" />
                    <div>
                      <p className="font-semibold text-blue-800">99.9% Uptime</p>
                      <p className="text-xs text-blue-600">Last 30 days</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-3 p-4 bg-purple-50 rounded-lg border border-purple-200">
                    <Shield className="h-5 w-5 text-purple-600" />
                    <div>
                      <p className="font-semibold text-purple-800">Security Active</p>
                      <p className="text-xs text-purple-600">All systems protected</p>
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="tenants" className="space-y-6">
            {/* Tenant List */}
            <Card>
              <CardHeader>
                <CardTitle>Tenant Management</CardTitle>
                <CardDescription>Manage all tenant organizations and their subscriptions</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {tenants.map((tenant) => (
                    <div key={tenant.id} className="flex items-center justify-between p-4 border rounded-lg hover:bg-gray-50 transition-colors">
                      <div className="flex items-center gap-4">
                        <div className="w-12 h-12 bg-gradient-to-br from-green-400 to-emerald-500 rounded-lg flex items-center justify-center">
                          <Building className="h-6 w-6 text-white" />
                        </div>
                        <div>
                          <h3 className="font-semibold">{tenant.name}</h3>
                          <p className="text-sm text-muted-foreground">{tenant.domain}</p>
                          <div className="flex items-center gap-2 mt-1">
                            <Badge className={getStatusColor(tenant.status)}>
                              {tenant.status}
                            </Badge>
                            <Badge className={getPlanColor(tenant.plan)}>
                              {tenant.plan}
                            </Badge>
                          </div>
                        </div>
                      </div>
                      <div className="text-right">
                        <p className="font-semibold">${tenant.monthlyRevenue}/month</p>
                        <p className="text-sm text-muted-foreground">{tenant.users} users, {tenant.sites} sites</p>
                        <div className="flex items-center gap-1 mt-2">
                          <Button variant="ghost" size="sm">
                            <Eye className="h-4 w-4" />
                          </Button>
                          <Button variant="ghost" size="sm">
                            <Edit className="h-4 w-4" />
                          </Button>
                          <Button variant="ghost" size="sm">
                            <Settings className="h-4 w-4" />
                          </Button>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="licenses" className="space-y-6">
            {/* License Types */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              {licenses.map((license) => (
                <Card key={license.id} className="relative overflow-hidden">
                  <div className="absolute top-0 right-0 w-16 h-16 bg-gradient-to-br from-purple-400/20 to-pink-500/20 rounded-full -translate-y-8 translate-x-8"></div>
                  <CardHeader>
                    <CardTitle className="flex items-center justify-between">
                      {license.type}
                      <Badge variant="secondary">{license.active} active</Badge>
                    </CardTitle>
                    <CardDescription>
                      Up to {license.maxUsers} users, {license.maxSites} sites
                    </CardDescription>
                  </CardHeader>
                  <CardContent>
                    <div className="space-y-3">
                      <div className="text-2xl font-bold text-green-600">
                        ${license.price}/month
                      </div>
                      <div className="space-y-2">
                        {license.features.map((feature, index) => (
                          <div key={index} className="flex items-center gap-2 text-sm">
                            <CheckCircle className="h-4 w-4 text-green-500" />
                            {feature}
                          </div>
                        ))}
                      </div>
                      <Button className="w-full mt-4">
                        Manage License
                      </Button>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          </TabsContent>
        </Tabs>
      </div>
    </DashboardLayout>
  );
};

export default SuperAdmin;