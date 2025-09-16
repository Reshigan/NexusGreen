import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../../../components/ui/card';
import { Button } from '../../../components/ui/button';
import { Badge } from '../../../components/ui/badge';
import { Input } from '../../../components/ui/input';
import { Label } from '../../../components/ui/label';
import { Textarea } from '../../../components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../../../components/ui/select';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from '../../../components/ui/dialog';
import { 
  Plus, 
  Search, 
  Filter, 
  MoreHorizontal, 
  Edit, 
  Trash2, 
  Eye,
  Building2,
  MapPin,
  Users,
  DollarSign,
  Calendar,
  TrendingUp,
  AlertCircle
} from 'lucide-react';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '../../../components/ui/dropdown-menu';

// Mock data - replace with actual API calls
const mockProjects = [
  {
    id: 1,
    name: 'Solar Farm Alpha',
    code: 'SFA-001',
    description: 'Large-scale solar installation for industrial complex',
    status: 'ACTIVE',
    customer: { name: 'ABC Manufacturing', email: 'contact@abc-mfg.com' },
    funder: { name: 'Green Energy Fund', email: 'invest@greenfund.com' },
    omProvider: { name: 'SolarTech O&M', email: 'ops@solartech.com' },
    totalCapacity: 2.5,
    totalInvestment: 4500000,
    expectedROI: 12.5,
    startDate: '2024-01-15',
    completionDate: '2024-06-30',
    sitesCount: 3,
    createdAt: '2024-01-01'
  },
  {
    id: 2,
    name: 'Corporate Rooftop Initiative',
    code: 'CRI-002',
    description: 'Distributed rooftop solar across multiple office buildings',
    status: 'PLANNING',
    customer: { name: 'XYZ Corporation', email: 'facilities@xyz-corp.com' },
    funder: { name: 'Sustainable Capital', email: 'deals@sustcap.com' },
    omProvider: { name: 'Maintenance Pro', email: 'service@maintpro.com' },
    totalCapacity: 1.8,
    totalInvestment: 3200000,
    expectedROI: 14.2,
    startDate: '2024-03-01',
    completionDate: '2024-08-15',
    sitesCount: 8,
    createdAt: '2024-02-15'
  },
  {
    id: 3,
    name: 'Community Solar Garden',
    code: 'CSG-003',
    description: 'Community-owned solar installation with battery storage',
    status: 'COMPLETED',
    customer: { name: 'Greenville Community', email: 'admin@greenville.org' },
    funder: { name: 'Community Investment Fund', email: 'info@cifund.org' },
    omProvider: { name: 'Local Energy Services', email: 'support@localenergy.com' },
    totalCapacity: 0.8,
    totalInvestment: 1800000,
    expectedROI: 10.8,
    startDate: '2023-09-01',
    completionDate: '2023-12-20',
    sitesCount: 1,
    createdAt: '2023-08-15'
  }
];

const ProjectManagement: React.FC = () => {
  const [projects, setProjects] = useState(mockProjects);
  const [filteredProjects, setFilteredProjects] = useState(mockProjects);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('ALL');
  const [isCreateDialogOpen, setIsCreateDialogOpen] = useState(false);
  const [selectedProject, setSelectedProject] = useState<any>(null);
  const [isEditDialogOpen, setIsEditDialogOpen] = useState(false);

  // Filter projects based on search and status
  useEffect(() => {
    let filtered = projects;

    if (searchTerm) {
      filtered = filtered.filter(project =>
        project.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        project.code.toLowerCase().includes(searchTerm.toLowerCase()) ||
        project.customer.name.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }

    if (statusFilter !== 'ALL') {
      filtered = filtered.filter(project => project.status === statusFilter);
    }

    setFilteredProjects(filtered);
  }, [projects, searchTerm, statusFilter]);

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'ACTIVE': return 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300';
      case 'PLANNING': return 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300';
      case 'COMPLETED': return 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-300';
      case 'CANCELLED': return 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300';
      default: return 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-300';
    }
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-ZA', {
      style: 'currency',
      currency: 'ZAR',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }).format(amount);
  };

  const handleCreateProject = () => {
    // Handle project creation
    setIsCreateDialogOpen(false);
  };

  const handleEditProject = (project: any) => {
    setSelectedProject(project);
    setIsEditDialogOpen(true);
  };

  const handleDeleteProject = (projectId: number) => {
    if (confirm('Are you sure you want to delete this project?')) {
      setProjects(projects.filter(p => p.id !== projectId));
    }
  };

  return (
    <div className="px-4 sm:px-6 lg:px-8">
      {/* Header */}
      <div className="mb-8">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold text-slate-900 dark:text-slate-100">
              Project Management
            </h1>
            <p className="mt-2 text-slate-600 dark:text-slate-400">
              Manage solar projects, assignments, and deployment
            </p>
          </div>
          <Dialog open={isCreateDialogOpen} onOpenChange={setIsCreateDialogOpen}>
            <DialogTrigger asChild>
              <Button>
                <Plus className="h-4 w-4 mr-2" />
                New Project
              </Button>
            </DialogTrigger>
            <DialogContent className="max-w-2xl">
              <DialogHeader>
                <DialogTitle>Create New Project</DialogTitle>
                <DialogDescription>
                  Set up a new solar energy project with stakeholder assignments
                </DialogDescription>
              </DialogHeader>
              <div className="grid grid-cols-2 gap-4 py-4">
                <div className="space-y-2">
                  <Label htmlFor="name">Project Name</Label>
                  <Input id="name" placeholder="Enter project name" />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="code">Project Code</Label>
                  <Input id="code" placeholder="e.g., SFA-001" />
                </div>
                <div className="col-span-2 space-y-2">
                  <Label htmlFor="description">Description</Label>
                  <Textarea id="description" placeholder="Project description" />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="customer">Customer</Label>
                  <Select>
                    <SelectTrigger>
                      <SelectValue placeholder="Select customer" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="customer1">ABC Manufacturing</SelectItem>
                      <SelectItem value="customer2">XYZ Corporation</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <div className="space-y-2">
                  <Label htmlFor="funder">Funder</Label>
                  <Select>
                    <SelectTrigger>
                      <SelectValue placeholder="Select funder" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="funder1">Green Energy Fund</SelectItem>
                      <SelectItem value="funder2">Sustainable Capital</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <div className="space-y-2">
                  <Label htmlFor="capacity">Total Capacity (MW)</Label>
                  <Input id="capacity" type="number" step="0.1" placeholder="2.5" />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="investment">Total Investment (ZAR)</Label>
                  <Input id="investment" type="number" placeholder="4500000" />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="startDate">Start Date</Label>
                  <Input id="startDate" type="date" />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="completionDate">Expected Completion</Label>
                  <Input id="completionDate" type="date" />
                </div>
              </div>
              <DialogFooter>
                <Button variant="outline" onClick={() => setIsCreateDialogOpen(false)}>
                  Cancel
                </Button>
                <Button onClick={handleCreateProject}>Create Project</Button>
              </DialogFooter>
            </DialogContent>
          </Dialog>
        </div>
      </div>

      {/* Filters */}
      <div className="mb-6 flex flex-col sm:flex-row gap-4">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-slate-400" />
          <Input
            placeholder="Search projects..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="pl-10"
          />
        </div>
        <Select value={statusFilter} onValueChange={setStatusFilter}>
          <SelectTrigger className="w-full sm:w-48">
            <SelectValue placeholder="Filter by status" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="ALL">All Status</SelectItem>
            <SelectItem value="PLANNING">Planning</SelectItem>
            <SelectItem value="ACTIVE">Active</SelectItem>
            <SelectItem value="COMPLETED">Completed</SelectItem>
            <SelectItem value="CANCELLED">Cancelled</SelectItem>
          </SelectContent>
        </Select>
      </div>

      {/* Projects Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-6">
        {filteredProjects.map((project) => (
          <Card key={project.id} className="hover:shadow-lg transition-shadow">
            <CardHeader className="pb-3">
              <div className="flex items-start justify-between">
                <div>
                  <CardTitle className="text-lg">{project.name}</CardTitle>
                  <CardDescription className="text-sm text-slate-500">
                    {project.code}
                  </CardDescription>
                </div>
                <div className="flex items-center space-x-2">
                  <Badge className={getStatusColor(project.status)}>
                    {project.status}
                  </Badge>
                  <DropdownMenu>
                    <DropdownMenuTrigger asChild>
                      <Button variant="ghost" size="sm">
                        <MoreHorizontal className="h-4 w-4" />
                      </Button>
                    </DropdownMenuTrigger>
                    <DropdownMenuContent align="end">
                      <DropdownMenuItem>
                        <Eye className="mr-2 h-4 w-4" />
                        View Details
                      </DropdownMenuItem>
                      <DropdownMenuItem onClick={() => handleEditProject(project)}>
                        <Edit className="mr-2 h-4 w-4" />
                        Edit Project
                      </DropdownMenuItem>
                      <DropdownMenuItem 
                        className="text-red-600"
                        onClick={() => handleDeleteProject(project.id)}
                      >
                        <Trash2 className="mr-2 h-4 w-4" />
                        Delete Project
                      </DropdownMenuItem>
                    </DropdownMenuContent>
                  </DropdownMenu>
                </div>
              </div>
            </CardHeader>
            <CardContent className="space-y-4">
              <p className="text-sm text-slate-600 dark:text-slate-400 line-clamp-2">
                {project.description}
              </p>
              
              {/* Key Metrics */}
              <div className="grid grid-cols-2 gap-4">
                <div className="flex items-center space-x-2">
                  <Building2 className="h-4 w-4 text-slate-400" />
                  <div>
                    <p className="text-xs text-slate-500">Capacity</p>
                    <p className="text-sm font-medium">{project.totalCapacity} MW</p>
                  </div>
                </div>
                <div className="flex items-center space-x-2">
                  <MapPin className="h-4 w-4 text-slate-400" />
                  <div>
                    <p className="text-xs text-slate-500">Sites</p>
                    <p className="text-sm font-medium">{project.sitesCount}</p>
                  </div>
                </div>
                <div className="flex items-center space-x-2">
                  <DollarSign className="h-4 w-4 text-slate-400" />
                  <div>
                    <p className="text-xs text-slate-500">Investment</p>
                    <p className="text-sm font-medium">{formatCurrency(project.totalInvestment)}</p>
                  </div>
                </div>
                <div className="flex items-center space-x-2">
                  <TrendingUp className="h-4 w-4 text-slate-400" />
                  <div>
                    <p className="text-xs text-slate-500">Expected ROI</p>
                    <p className="text-sm font-medium">{project.expectedROI}%</p>
                  </div>
                </div>
              </div>

              {/* Stakeholders */}
              <div className="space-y-2">
                <p className="text-xs font-medium text-slate-500 uppercase tracking-wide">Stakeholders</p>
                <div className="space-y-1">
                  <div className="flex items-center justify-between text-xs">
                    <span className="text-slate-500">Customer:</span>
                    <span className="font-medium">{project.customer.name}</span>
                  </div>
                  <div className="flex items-center justify-between text-xs">
                    <span className="text-slate-500">Funder:</span>
                    <span className="font-medium">{project.funder.name}</span>
                  </div>
                  <div className="flex items-center justify-between text-xs">
                    <span className="text-slate-500">O&M:</span>
                    <span className="font-medium">{project.omProvider.name}</span>
                  </div>
                </div>
              </div>

              {/* Timeline */}
              <div className="flex items-center justify-between text-xs text-slate-500">
                <div className="flex items-center">
                  <Calendar className="h-3 w-3 mr-1" />
                  {new Date(project.startDate).toLocaleDateString()}
                </div>
                <div>
                  → {new Date(project.completionDate).toLocaleDateString()}
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Empty State */}
      {filteredProjects.length === 0 && (
        <div className="text-center py-12">
          <Building2 className="mx-auto h-12 w-12 text-slate-400" />
          <h3 className="mt-2 text-sm font-medium text-slate-900 dark:text-slate-100">No projects found</h3>
          <p className="mt-1 text-sm text-slate-500">
            {searchTerm || statusFilter !== 'ALL' 
              ? 'Try adjusting your search or filter criteria.'
              : 'Get started by creating your first project.'
            }
          </p>
          {!searchTerm && statusFilter === 'ALL' && (
            <div className="mt-6">
              <Button onClick={() => setIsCreateDialogOpen(true)}>
                <Plus className="h-4 w-4 mr-2" />
                New Project
              </Button>
            </div>
          )}
        </div>
      )}
    </div>
  );
};

export default ProjectManagement;