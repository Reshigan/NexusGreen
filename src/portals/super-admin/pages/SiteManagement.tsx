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
  MapPin,
  Zap,
  Battery,
  Wifi,
  Calendar,
  TrendingUp,
  AlertTriangle,
  CheckCircle,
  Settings
} from 'lucide-react';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '../../../components/ui/dropdown-menu';

// Mock data - replace with actual API calls
const mockSites = [
  {
    id: 1,
    name: 'Johannesburg Office Complex',
    code: 'JHB-001',
    projectId: 1,
    projectName: 'Solar Farm Alpha',
    address: '123 Business Park, Sandton, Johannesburg',
    latitude: -26.1076,
    longitude: 28.0567,
    municipality: 'City of Johannesburg',
    capacity: 850,
    systemType: 'GRID_TIED',
    batteryCapacity: 0,
    inverterCapacity: 800,
    panelCount: 2125,
    installationDate: '2024-02-15',
    commissioningDate: '2024-03-01',
    status: 'ACTIVE',
    timezone: 'Africa/Johannesburg',
    elevation: 1753,
    tiltAngle: 25,
    azimuthAngle: 180,
    currentProduction: 425.5,
    todayYield: 3420,
    monthlyYield: 89500,
    efficiency: 94.2,
    uptime: 99.1,
    lastMaintenance: '2024-08-15',
    nextMaintenance: '2024-11-15'
  },
  {
    id: 2,
    name: 'Cape Town Manufacturing Plant',
    code: 'CPT-002',
    projectId: 1,
    projectName: 'Solar Farm Alpha',
    address: '456 Industrial Ave, Bellville, Cape Town',
    latitude: -33.8886,
    longitude: 18.6309,
    municipality: 'City of Cape Town',
    capacity: 1200,
    systemType: 'HYBRID',
    batteryCapacity: 500,
    inverterCapacity: 1100,
    panelCount: 3000,
    installationDate: '2024-01-20',
    commissioningDate: '2024-02-10',
    status: 'ACTIVE',
    timezone: 'Africa/Johannesburg',
    elevation: 42,
    tiltAngle: 30,
    azimuthAngle: 180,
    currentProduction: 680.2,
    todayYield: 5240,
    monthlyYield: 142800,
    efficiency: 96.8,
    uptime: 98.7,
    lastMaintenance: '2024-07-20',
    nextMaintenance: '2024-10-20'
  },
  {
    id: 3,
    name: 'Durban Warehouse Facility',
    code: 'DBN-003',
    projectId: 2,
    projectName: 'Corporate Rooftop Initiative',
    address: '789 Logistics Hub, Pinetown, Durban',
    latitude: -29.8587,
    longitude: 31.0218,
    municipality: 'eThekwini Municipality',
    capacity: 450,
    systemType: 'GRID_TIED',
    batteryCapacity: 0,
    inverterCapacity: 400,
    panelCount: 1125,
    installationDate: '2024-04-10',
    commissioningDate: '2024-04-25',
    status: 'MAINTENANCE',
    timezone: 'Africa/Johannesburg',
    elevation: 258,
    tiltAngle: 28,
    azimuthAngle: 180,
    currentProduction: 0,
    todayYield: 0,
    monthlyYield: 45200,
    efficiency: 0,
    uptime: 85.3,
    lastMaintenance: '2024-09-10',
    nextMaintenance: '2024-09-20'
  }
];

const SiteManagement: React.FC = () => {
  const [sites, setSites] = useState(mockSites);
  const [filteredSites, setFilteredSites] = useState(mockSites);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('ALL');
  const [systemTypeFilter, setSystemTypeFilter] = useState('ALL');
  const [isCreateDialogOpen, setIsCreateDialogOpen] = useState(false);
  const [selectedSite, setSelectedSite] = useState<any>(null);
  const [isEditDialogOpen, setIsEditDialogOpen] = useState(false);

  // Filter sites based on search and filters
  useEffect(() => {
    let filtered = sites;

    if (searchTerm) {
      filtered = filtered.filter(site =>
        site.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        site.code.toLowerCase().includes(searchTerm.toLowerCase()) ||
        site.address.toLowerCase().includes(searchTerm.toLowerCase()) ||
        site.municipality.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }

    if (statusFilter !== 'ALL') {
      filtered = filtered.filter(site => site.status === statusFilter);
    }

    if (systemTypeFilter !== 'ALL') {
      filtered = filtered.filter(site => site.systemType === systemTypeFilter);
    }

    setFilteredSites(filtered);
  }, [sites, searchTerm, statusFilter, systemTypeFilter]);

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'ACTIVE': return 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300';
      case 'PLANNING': return 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300';
      case 'INSTALLING': return 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300';
      case 'MAINTENANCE': return 'bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-300';
      case 'DECOMMISSIONED': return 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300';
      default: return 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-300';
    }
  };

  const getSystemTypeIcon = (type: string) => {
    switch (type) {
      case 'GRID_TIED': return <Wifi className="h-4 w-4" />;
      case 'HYBRID': return <Battery className="h-4 w-4" />;
      case 'OFF_GRID': return <Zap className="h-4 w-4" />;
      default: return <Zap className="h-4 w-4" />;
    }
  };

  const formatPower = (kw: number) => {
    if (kw >= 1000) {
      return `${(kw / 1000).toFixed(1)} MW`;
    }
    return `${kw} kW`;
  };

  const formatEnergy = (kwh: number) => {
    if (kwh >= 1000) {
      return `${(kwh / 1000).toFixed(1)} MWh`;
    }
    return `${kwh} kWh`;
  };

  const handleCreateSite = () => {
    // Handle site creation
    setIsCreateDialogOpen(false);
  };

  const handleEditSite = (site: any) => {
    setSelectedSite(site);
    setIsEditDialogOpen(true);
  };

  const handleDeleteSite = (siteId: number) => {
    if (confirm('Are you sure you want to delete this site?')) {
      setSites(sites.filter(s => s.id !== siteId));
    }
  };

  return (
    <div className="px-4 sm:px-6 lg:px-8">
      {/* Header */}
      <div className="mb-8">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold text-slate-900 dark:text-slate-100">
              Site Management
            </h1>
            <p className="mt-2 text-slate-600 dark:text-slate-400">
              Monitor and manage solar installation sites
            </p>
          </div>
          <Dialog open={isCreateDialogOpen} onOpenChange={setIsCreateDialogOpen}>
            <DialogTrigger asChild>
              <Button>
                <Plus className="h-4 w-4 mr-2" />
                New Site
              </Button>
            </DialogTrigger>
            <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto">
              <DialogHeader>
                <DialogTitle>Create New Site</DialogTitle>
                <DialogDescription>
                  Add a new solar installation site to the system
                </DialogDescription>
              </DialogHeader>
              <div className="grid grid-cols-2 gap-4 py-4">
                <div className="space-y-2">
                  <Label htmlFor="siteName">Site Name</Label>
                  <Input id="siteName" placeholder="Enter site name" />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="siteCode">Site Code</Label>
                  <Input id="siteCode" placeholder="e.g., JHB-001" />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="project">Project</Label>
                  <Select>
                    <SelectTrigger>
                      <SelectValue placeholder="Select project" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="1">Solar Farm Alpha</SelectItem>
                      <SelectItem value="2">Corporate Rooftop Initiative</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <div className="space-y-2">
                  <Label htmlFor="systemType">System Type</Label>
                  <Select>
                    <SelectTrigger>
                      <SelectValue placeholder="Select system type" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="GRID_TIED">Grid Tied</SelectItem>
                      <SelectItem value="HYBRID">Hybrid (Grid + Battery)</SelectItem>
                      <SelectItem value="OFF_GRID">Off Grid</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <div className="col-span-2 space-y-2">
                  <Label htmlFor="address">Address</Label>
                  <Textarea id="address" placeholder="Full site address" />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="latitude">Latitude</Label>
                  <Input id="latitude" type="number" step="0.000001" placeholder="-26.1076" />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="longitude">Longitude</Label>
                  <Input id="longitude" type="number" step="0.000001" placeholder="28.0567" />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="municipality">Municipality</Label>
                  <Input id="municipality" placeholder="City of Johannesburg" />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="capacity">Capacity (kW)</Label>
                  <Input id="capacity" type="number" placeholder="850" />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="batteryCapacity">Battery Capacity (kWh)</Label>
                  <Input id="batteryCapacity" type="number" placeholder="0" />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="inverterCapacity">Inverter Capacity (kW)</Label>
                  <Input id="inverterCapacity" type="number" placeholder="800" />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="panelCount">Panel Count</Label>
                  <Input id="panelCount" type="number" placeholder="2125" />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="tiltAngle">Tilt Angle (°)</Label>
                  <Input id="tiltAngle" type="number" step="0.1" placeholder="25" />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="azimuthAngle">Azimuth Angle (°)</Label>
                  <Input id="azimuthAngle" type="number" step="0.1" placeholder="180" />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="installationDate">Installation Date</Label>
                  <Input id="installationDate" type="date" />
                </div>
              </div>
              <DialogFooter>
                <Button variant="outline" onClick={() => setIsCreateDialogOpen(false)}>
                  Cancel
                </Button>
                <Button onClick={handleCreateSite}>Create Site</Button>
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
            placeholder="Search sites..."
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
            <SelectItem value="INSTALLING">Installing</SelectItem>
            <SelectItem value="ACTIVE">Active</SelectItem>
            <SelectItem value="MAINTENANCE">Maintenance</SelectItem>
            <SelectItem value="DECOMMISSIONED">Decommissioned</SelectItem>
          </SelectContent>
        </Select>
        <Select value={systemTypeFilter} onValueChange={setSystemTypeFilter}>
          <SelectTrigger className="w-full sm:w-48">
            <SelectValue placeholder="Filter by type" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="ALL">All Types</SelectItem>
            <SelectItem value="GRID_TIED">Grid Tied</SelectItem>
            <SelectItem value="HYBRID">Hybrid</SelectItem>
            <SelectItem value="OFF_GRID">Off Grid</SelectItem>
          </SelectContent>
        </Select>
      </div>

      {/* Sites Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-6">
        {filteredSites.map((site) => (
          <Card key={site.id} className="hover:shadow-lg transition-shadow">
            <CardHeader className="pb-3">
              <div className="flex items-start justify-between">
                <div>
                  <CardTitle className="text-lg">{site.name}</CardTitle>
                  <CardDescription className="text-sm text-slate-500">
                    {site.code} • {site.projectName}
                  </CardDescription>
                </div>
                <div className="flex items-center space-x-2">
                  <Badge className={getStatusColor(site.status)}>
                    {site.status}
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
                      <DropdownMenuItem onClick={() => handleEditSite(site)}>
                        <Edit className="mr-2 h-4 w-4" />
                        Edit Site
                      </DropdownMenuItem>
                      <DropdownMenuItem>
                        <Settings className="mr-2 h-4 w-4" />
                        Configure
                      </DropdownMenuItem>
                      <DropdownMenuItem 
                        className="text-red-600"
                        onClick={() => handleDeleteSite(site.id)}
                      >
                        <Trash2 className="mr-2 h-4 w-4" />
                        Delete Site
                      </DropdownMenuItem>
                    </DropdownMenuContent>
                  </DropdownMenu>
                </div>
              </div>
            </CardHeader>
            <CardContent className="space-y-4">
              {/* Location */}
              <div className="flex items-start space-x-2">
                <MapPin className="h-4 w-4 text-slate-400 mt-0.5" />
                <div className="flex-1">
                  <p className="text-sm text-slate-600 dark:text-slate-400 line-clamp-2">
                    {site.address}
                  </p>
                  <p className="text-xs text-slate-500">{site.municipality}</p>
                </div>
              </div>

              {/* System Info */}
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-2">
                  {getSystemTypeIcon(site.systemType)}
                  <span className="text-sm font-medium">
                    {site.systemType.replace('_', ' ')}
                  </span>
                </div>
                <div className="text-right">
                  <p className="text-sm font-medium">{formatPower(site.capacity)}</p>
                  <p className="text-xs text-slate-500">{site.panelCount} panels</p>
                </div>
              </div>

              {/* Performance Metrics */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <p className="text-xs text-slate-500">Current Output</p>
                  <p className="text-sm font-medium">{formatPower(site.currentProduction)}</p>
                </div>
                <div>
                  <p className="text-xs text-slate-500">Today's Yield</p>
                  <p className="text-sm font-medium">{formatEnergy(site.todayYield)}</p>
                </div>
                <div>
                  <p className="text-xs text-slate-500">Efficiency</p>
                  <p className="text-sm font-medium">{site.efficiency}%</p>
                </div>
                <div>
                  <p className="text-xs text-slate-500">Uptime</p>
                  <p className="text-sm font-medium">{site.uptime}%</p>
                </div>
              </div>

              {/* Status Indicators */}
              <div className="flex items-center justify-between pt-2 border-t border-slate-200 dark:border-slate-700">
                <div className="flex items-center space-x-4">
                  {site.status === 'ACTIVE' ? (
                    <div className="flex items-center space-x-1">
                      <CheckCircle className="h-3 w-3 text-green-500" />
                      <span className="text-xs text-green-600">Online</span>
                    </div>
                  ) : site.status === 'MAINTENANCE' ? (
                    <div className="flex items-center space-x-1">
                      <AlertTriangle className="h-3 w-3 text-orange-500" />
                      <span className="text-xs text-orange-600">Maintenance</span>
                    </div>
                  ) : (
                    <div className="flex items-center space-x-1">
                      <div className="h-3 w-3 bg-slate-400 rounded-full" />
                      <span className="text-xs text-slate-500">Offline</span>
                    </div>
                  )}
                </div>
                <div className="text-xs text-slate-500">
                  Next: {new Date(site.nextMaintenance).toLocaleDateString()}
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Empty State */}
      {filteredSites.length === 0 && (
        <div className="text-center py-12">
          <MapPin className="mx-auto h-12 w-12 text-slate-400" />
          <h3 className="mt-2 text-sm font-medium text-slate-900 dark:text-slate-100">No sites found</h3>
          <p className="mt-1 text-sm text-slate-500">
            {searchTerm || statusFilter !== 'ALL' || systemTypeFilter !== 'ALL'
              ? 'Try adjusting your search or filter criteria.'
              : 'Get started by creating your first site.'
            }
          </p>
          {!searchTerm && statusFilter === 'ALL' && systemTypeFilter === 'ALL' && (
            <div className="mt-6">
              <Button onClick={() => setIsCreateDialogOpen(true)}>
                <Plus className="h-4 w-4 mr-2" />
                New Site
              </Button>
            </div>
          )}
        </div>
      )}
    </div>
  );
};

export default SiteManagement;