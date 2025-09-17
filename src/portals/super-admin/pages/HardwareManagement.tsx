import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../../../components/ui/card';
import { Button } from '../../../components/ui/button';
import { Badge } from '../../../components/ui/badge';
import { Input } from '../../../components/ui/input';
import { Label } from '../../../components/ui/label';
import { Textarea } from '../../../components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../../../components/ui/select';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from '../../../components/ui/dialog';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../../../components/ui/tabs';
import { 
  Plus, 
  Search, 
  Filter, 
  MoreHorizontal, 
  Edit, 
  Trash2, 
  Eye,
  HardDrive,
  Zap,
  Battery,
  Monitor,
  Wrench,
  Calendar,
  AlertTriangle,
  CheckCircle,
  Clock,
  Package,
  FileText,
  Download
} from 'lucide-react';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '../../../components/ui/dropdown-menu';

// Mock data - replace with actual API calls
const mockEquipmentTypes = [
  {
    id: 1,
    category: 'PANEL',
    manufacturer: 'Canadian Solar',
    model: 'CS3W-400P',
    specifications: {
      power_w: 400,
      efficiency: 20.3,
      voltage_v: 37.8,
      current_a: 10.58,
      dimensions: '2108x1048x40mm',
      weight_kg: 22.5
    },
    warrantyYears: 25,
    datasheetUrl: '/datasheets/canadian-solar-cs3w-400p.pdf',
    createdAt: '2024-01-01T00:00:00Z'
  },
  {
    id: 2,
    category: 'INVERTER',
    manufacturer: 'SMA',
    model: 'STP 25000TL-30',
    specifications: {
      power_kw: 25,
      efficiency: 98.2,
      input_voltage_range: '580-1000V',
      mppt_trackers: 3,
      dimensions: '665x460x242mm',
      weight_kg: 34
    },
    warrantyYears: 10,
    datasheetUrl: '/datasheets/sma-stp-25000tl-30.pdf',
    createdAt: '2024-01-01T00:00:00Z'
  },
  {
    id: 3,
    category: 'BATTERY',
    manufacturer: 'Tesla',
    model: 'Powerwall 2',
    specifications: {
      capacity_kwh: 13.5,
      power_kw: 5,
      efficiency: 90,
      cycles: 5000,
      dimensions: '1150x755x155mm',
      weight_kg: 114
    },
    warrantyYears: 10,
    datasheetUrl: '/datasheets/tesla-powerwall-2.pdf',
    createdAt: '2024-01-01T00:00:00Z'
  }
];

const mockSiteEquipment = [
  {
    id: 1,
    siteId: 1,
    siteName: 'Johannesburg Office Complex',
    equipmentTypeId: 1,
    equipmentType: mockEquipmentTypes[0],
    serialNumber: 'CS400-2024-001',
    quantity: 2125,
    installationDate: '2024-02-15',
    warrantyStartDate: '2024-02-15',
    warrantyEndDate: '2049-02-15',
    status: 'ACTIVE',
    maintenanceSchedule: 'ANNUALLY',
    lastMaintenanceDate: '2024-08-15',
    nextMaintenanceDate: '2025-08-15',
    notes: 'Rooftop installation, south-facing orientation'
  },
  {
    id: 2,
    siteId: 1,
    siteName: 'Johannesburg Office Complex',
    equipmentTypeId: 2,
    equipmentType: mockEquipmentTypes[1],
    serialNumber: 'SMA-25K-2024-001',
    quantity: 1,
    installationDate: '2024-02-20',
    warrantyStartDate: '2024-02-20',
    warrantyEndDate: '2034-02-20',
    status: 'ACTIVE',
    maintenanceSchedule: 'QUARTERLY',
    lastMaintenanceDate: '2024-09-01',
    nextMaintenanceDate: '2024-12-01',
    notes: 'Main inverter for rooftop array'
  },
  {
    id: 3,
    siteId: 2,
    siteName: 'Cape Town Manufacturing Plant',
    equipmentTypeId: 3,
    equipmentType: mockEquipmentTypes[2],
    serialNumber: 'TESLA-PW2-2024-001',
    quantity: 4,
    installationDate: '2024-01-25',
    warrantyStartDate: '2024-01-25',
    warrantyEndDate: '2034-01-25',
    status: 'MAINTENANCE',
    maintenanceSchedule: 'QUARTERLY',
    lastMaintenanceDate: '2024-09-10',
    nextMaintenanceDate: '2024-09-20',
    notes: 'Battery bank for energy storage, currently under maintenance'
  }
];

const HardwareManagement: React.FC = () => {
  const [activeTab, setActiveTab] = useState('equipment');
  const [equipmentTypes, setEquipmentTypes] = useState(mockEquipmentTypes);
  const [siteEquipment, setSiteEquipment] = useState(mockSiteEquipment);
  const [filteredEquipment, setFilteredEquipment] = useState(mockSiteEquipment);
  const [searchTerm, setSearchTerm] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('ALL');
  const [statusFilter, setStatusFilter] = useState('ALL');
  const [isCreateTypeDialogOpen, setIsCreateTypeDialogOpen] = useState(false);
  const [isCreateEquipmentDialogOpen, setIsCreateEquipmentDialogOpen] = useState(false);

  // Filter equipment based on search and filters
  useEffect(() => {
    let filtered = siteEquipment;

    if (searchTerm) {
      filtered = filtered.filter(equipment =>
        equipment.siteName.toLowerCase().includes(searchTerm.toLowerCase()) ||
        equipment.equipmentType.manufacturer.toLowerCase().includes(searchTerm.toLowerCase()) ||
        equipment.equipmentType.model.toLowerCase().includes(searchTerm.toLowerCase()) ||
        equipment.serialNumber.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }

    if (categoryFilter !== 'ALL') {
      filtered = filtered.filter(equipment => equipment.equipmentType.category === categoryFilter);
    }

    if (statusFilter !== 'ALL') {
      filtered = filtered.filter(equipment => equipment.status === statusFilter);
    }

    setFilteredEquipment(filtered);
  }, [siteEquipment, searchTerm, categoryFilter, statusFilter]);

  const getCategoryIcon = (category: string) => {
    switch (category) {
      case 'PANEL': return <Zap className="h-4 w-4" />;
      case 'INVERTER': return <HardDrive className="h-4 w-4" />;
      case 'BATTERY': return <Battery className="h-4 w-4" />;
      case 'MONITORING': return <Monitor className="h-4 w-4" />;
      case 'MOUNTING': return <Package className="h-4 w-4" />;
      default: return <HardDrive className="h-4 w-4" />;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'ACTIVE': return 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300';
      case 'MAINTENANCE': return 'bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-300';
      case 'FAULTY': return 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300';
      case 'REPLACED': return 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-300';
      default: return 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-300';
    }
  };

  const getMaintenanceStatusColor = (nextMaintenanceDate: string) => {
    const nextDate = new Date(nextMaintenanceDate);
    const today = new Date();
    const daysUntil = Math.ceil((nextDate.getTime() - today.getTime()) / (1000 * 3600 * 24));

    if (daysUntil < 0) return 'text-red-600'; // Overdue
    if (daysUntil <= 7) return 'text-orange-600'; // Due soon
    return 'text-green-600'; // On schedule
  };

  const handleCreateEquipmentType = () => {
    // Handle equipment type creation
    setIsCreateTypeDialogOpen(false);
  };

  const handleCreateSiteEquipment = () => {
    // Handle site equipment creation
    setIsCreateEquipmentDialogOpen(false);
  };

  return (
    <div className="px-4 sm:px-6 lg:px-8">
      {/* Header */}
      <div className="mb-8">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold text-slate-900 dark:text-slate-100">
              Hardware Management
            </h1>
            <p className="mt-2 text-slate-600 dark:text-slate-400">
              Manage equipment types, site installations, and maintenance schedules
            </p>
          </div>
        </div>
      </div>

      {/* Tabs */}
      <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-6">
        <TabsList className="grid w-full grid-cols-3">
          <TabsTrigger value="equipment">Site Equipment</TabsTrigger>
          <TabsTrigger value="types">Equipment Types</TabsTrigger>
          <TabsTrigger value="maintenance">Maintenance</TabsTrigger>
        </TabsList>

        {/* Site Equipment Tab */}
        <TabsContent value="equipment" className="space-y-6">
          {/* Stats Cards */}
          <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
            <Card>
              <CardContent className="p-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-medium text-slate-600 dark:text-slate-400">Total Equipment</p>
                    <p className="text-3xl font-bold text-slate-900 dark:text-slate-100">
                      {siteEquipment.reduce((sum, eq) => sum + eq.quantity, 0)}
                    </p>
                  </div>
                  <Package className="h-8 w-8 text-blue-600" />
                </div>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="p-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-medium text-slate-600 dark:text-slate-400">Active</p>
                    <p className="text-3xl font-bold text-slate-900 dark:text-slate-100">
                      {siteEquipment.filter(eq => eq.status === 'ACTIVE').reduce((sum, eq) => sum + eq.quantity, 0)}
                    </p>
                  </div>
                  <CheckCircle className="h-8 w-8 text-green-600" />
                </div>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="p-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-medium text-slate-600 dark:text-slate-400">Maintenance</p>
                    <p className="text-3xl font-bold text-slate-900 dark:text-slate-100">
                      {siteEquipment.filter(eq => eq.status === 'MAINTENANCE').reduce((sum, eq) => sum + eq.quantity, 0)}
                    </p>
                  </div>
                  <Wrench className="h-8 w-8 text-orange-600" />
                </div>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="p-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-medium text-slate-600 dark:text-slate-400">Due Maintenance</p>
                    <p className="text-3xl font-bold text-slate-900 dark:text-slate-100">
                      {siteEquipment.filter(eq => {
                        const nextDate = new Date(eq.nextMaintenanceDate);
                        const today = new Date();
                        return nextDate <= new Date(today.getTime() + 7 * 24 * 60 * 60 * 1000);
                      }).length}
                    </p>
                  </div>
                  <Clock className="h-8 w-8 text-red-600" />
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Filters and Actions */}
          <div className="flex items-center justify-between">
            <div className="flex flex-col sm:flex-row gap-4 flex-1">
              <div className="relative flex-1">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-slate-400" />
                <Input
                  placeholder="Search equipment..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="pl-10"
                />
              </div>
              <Select value={categoryFilter} onValueChange={setCategoryFilter}>
                <SelectTrigger className="w-full sm:w-48">
                  <SelectValue placeholder="Filter by category" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="ALL">All Categories</SelectItem>
                  <SelectItem value="PANEL">Solar Panels</SelectItem>
                  <SelectItem value="INVERTER">Inverters</SelectItem>
                  <SelectItem value="BATTERY">Batteries</SelectItem>
                  <SelectItem value="MONITORING">Monitoring</SelectItem>
                  <SelectItem value="MOUNTING">Mounting</SelectItem>
                </SelectContent>
              </Select>
              <Select value={statusFilter} onValueChange={setStatusFilter}>
                <SelectTrigger className="w-full sm:w-48">
                  <SelectValue placeholder="Filter by status" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="ALL">All Status</SelectItem>
                  <SelectItem value="ACTIVE">Active</SelectItem>
                  <SelectItem value="MAINTENANCE">Maintenance</SelectItem>
                  <SelectItem value="FAULTY">Faulty</SelectItem>
                  <SelectItem value="REPLACED">Replaced</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <Dialog open={isCreateEquipmentDialogOpen} onOpenChange={setIsCreateEquipmentDialogOpen}>
              <DialogTrigger asChild>
                <Button className="ml-4">
                  <Plus className="h-4 w-4 mr-2" />
                  Add Equipment
                </Button>
              </DialogTrigger>
              <DialogContent className="max-w-2xl">
                <DialogHeader>
                  <DialogTitle>Add Site Equipment</DialogTitle>
                  <DialogDescription>
                    Install new equipment at a site
                  </DialogDescription>
                </DialogHeader>
                <div className="grid grid-cols-2 gap-4 py-4">
                  <div className="space-y-2">
                    <Label htmlFor="site">Site</Label>
                    <Select>
                      <SelectTrigger>
                        <SelectValue placeholder="Select site" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="1">Johannesburg Office Complex</SelectItem>
                        <SelectItem value="2">Cape Town Manufacturing Plant</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="equipmentType">Equipment Type</Label>
                    <Select>
                      <SelectTrigger>
                        <SelectValue placeholder="Select equipment type" />
                      </SelectTrigger>
                      <SelectContent>
                        {equipmentTypes.map(type => (
                          <SelectItem key={type.id} value={type.id.toString()}>
                            {type.manufacturer} {type.model}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="serialNumber">Serial Number</Label>
                    <Input id="serialNumber" placeholder="Enter serial number" />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="quantity">Quantity</Label>
                    <Input id="quantity" type="number" placeholder="1" />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="installationDate">Installation Date</Label>
                    <Input id="installationDate" type="date" />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="maintenanceSchedule">Maintenance Schedule</Label>
                    <Select>
                      <SelectTrigger>
                        <SelectValue placeholder="Select schedule" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="MONTHLY">Monthly</SelectItem>
                        <SelectItem value="QUARTERLY">Quarterly</SelectItem>
                        <SelectItem value="ANNUALLY">Annually</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                  <div className="col-span-2 space-y-2">
                    <Label htmlFor="notes">Notes</Label>
                    <Textarea id="notes" placeholder="Installation notes and comments" />
                  </div>
                </div>
                <DialogFooter>
                  <Button variant="outline" onClick={() => setIsCreateEquipmentDialogOpen(false)}>
                    Cancel
                  </Button>
                  <Button onClick={handleCreateSiteEquipment}>Add Equipment</Button>
                </DialogFooter>
              </DialogContent>
            </Dialog>
          </div>

          {/* Equipment List */}
          <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-6">
            {filteredEquipment.map((equipment) => (
              <Card key={equipment.id} className="hover:shadow-lg transition-shadow">
                <CardHeader className="pb-3">
                  <div className="flex items-start justify-between">
                    <div className="flex items-center space-x-2">
                      {getCategoryIcon(equipment.equipmentType.category)}
                      <div>
                        <CardTitle className="text-lg">
                          {equipment.equipmentType.manufacturer} {equipment.equipmentType.model}
                        </CardTitle>
                        <CardDescription className="text-sm">
                          {equipment.siteName}
                        </CardDescription>
                      </div>
                    </div>
                    <Badge className={getStatusColor(equipment.status)}>
                      {equipment.status}
                    </Badge>
                  </div>
                </CardHeader>
                <CardContent className="space-y-4">
                  {/* Equipment Details */}
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <p className="text-xs text-slate-500">Serial Number</p>
                      <p className="text-sm font-medium">{equipment.serialNumber}</p>
                    </div>
                    <div>
                      <p className="text-xs text-slate-500">Quantity</p>
                      <p className="text-sm font-medium">{equipment.quantity}</p>
                    </div>
                    <div>
                      <p className="text-xs text-slate-500">Installed</p>
                      <p className="text-sm font-medium">
                        {new Date(equipment.installationDate).toLocaleDateString()}
                      </p>
                    </div>
                    <div>
                      <p className="text-xs text-slate-500">Warranty Until</p>
                      <p className="text-sm font-medium">
                        {new Date(equipment.warrantyEndDate).toLocaleDateString()}
                      </p>
                    </div>
                  </div>

                  {/* Maintenance Info */}
                  <div className="pt-3 border-t border-slate-200 dark:border-slate-700">
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-xs font-medium text-slate-500 uppercase tracking-wide">
                        Maintenance
                      </span>
                      <Badge variant="outline" className="text-xs">
                        {equipment.maintenanceSchedule}
                      </Badge>
                    </div>
                    <div className="grid grid-cols-2 gap-2 text-xs">
                      <div>
                        <p className="text-slate-500">Last Service</p>
                        <p className="font-medium">
                          {new Date(equipment.lastMaintenanceDate).toLocaleDateString()}
                        </p>
                      </div>
                      <div>
                        <p className="text-slate-500">Next Service</p>
                        <p className={`font-medium ${getMaintenanceStatusColor(equipment.nextMaintenanceDate)}`}>
                          {new Date(equipment.nextMaintenanceDate).toLocaleDateString()}
                        </p>
                      </div>
                    </div>
                  </div>

                  {/* Notes */}
                  {equipment.notes && (
                    <div className="pt-2 border-t border-slate-200 dark:border-slate-700">
                      <p className="text-xs text-slate-600 dark:text-slate-400 line-clamp-2">
                        {equipment.notes}
                      </p>
                    </div>
                  )}

                  {/* Actions */}
                  <div className="flex items-center justify-between pt-2">
                    <Button variant="outline" size="sm">
                      <Wrench className="h-3 w-3 mr-1" />
                      Schedule Maintenance
                    </Button>
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
                        <DropdownMenuItem>
                          <Edit className="mr-2 h-4 w-4" />
                          Edit Equipment
                        </DropdownMenuItem>
                        <DropdownMenuItem>
                          <FileText className="mr-2 h-4 w-4" />
                          View Datasheet
                        </DropdownMenuItem>
                        <DropdownMenuItem className="text-red-600">
                          <Trash2 className="mr-2 h-4 w-4" />
                          Remove Equipment
                        </DropdownMenuItem>
                      </DropdownMenuContent>
                    </DropdownMenu>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </TabsContent>

        {/* Equipment Types Tab */}
        <TabsContent value="types" className="space-y-6">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-2xl font-bold text-slate-900 dark:text-slate-100">Equipment Catalog</h2>
              <p className="text-slate-600 dark:text-slate-400">Manage equipment types and specifications</p>
            </div>
            <Dialog open={isCreateTypeDialogOpen} onOpenChange={setIsCreateTypeDialogOpen}>
              <DialogTrigger asChild>
                <Button>
                  <Plus className="h-4 w-4 mr-2" />
                  Add Equipment Type
                </Button>
              </DialogTrigger>
              <DialogContent className="max-w-3xl">
                <DialogHeader>
                  <DialogTitle>Add Equipment Type</DialogTitle>
                  <DialogDescription>
                    Add a new equipment type to the catalog
                  </DialogDescription>
                </DialogHeader>
                <div className="grid grid-cols-2 gap-4 py-4">
                  <div className="space-y-2">
                    <Label htmlFor="category">Category</Label>
                    <Select>
                      <SelectTrigger>
                        <SelectValue placeholder="Select category" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="PANEL">Solar Panel</SelectItem>
                        <SelectItem value="INVERTER">Inverter</SelectItem>
                        <SelectItem value="BATTERY">Battery</SelectItem>
                        <SelectItem value="MONITORING">Monitoring</SelectItem>
                        <SelectItem value="MOUNTING">Mounting</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="manufacturer">Manufacturer</Label>
                    <Input id="manufacturer" placeholder="e.g., Canadian Solar" />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="model">Model</Label>
                    <Input id="model" placeholder="e.g., CS3W-400P" />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="warrantyYears">Warranty (Years)</Label>
                    <Input id="warrantyYears" type="number" placeholder="25" />
                  </div>
                  <div className="col-span-2 space-y-2">
                    <Label htmlFor="specifications">Specifications (JSON)</Label>
                    <Textarea 
                      id="specifications" 
                      placeholder='{"power_w": 400, "efficiency": 20.3, "voltage_v": 37.8}'
                      rows={4}
                    />
                  </div>
                  <div className="col-span-2 space-y-2">
                    <Label htmlFor="datasheetUrl">Datasheet URL</Label>
                    <Input id="datasheetUrl" placeholder="/datasheets/equipment-datasheet.pdf" />
                  </div>
                </div>
                <DialogFooter>
                  <Button variant="outline" onClick={() => setIsCreateTypeDialogOpen(false)}>
                    Cancel
                  </Button>
                  <Button onClick={handleCreateEquipmentType}>Add Equipment Type</Button>
                </DialogFooter>
              </DialogContent>
            </Dialog>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {equipmentTypes.map((type) => (
              <Card key={type.id} className="hover:shadow-lg transition-shadow">
                <CardHeader>
                  <div className="flex items-start justify-between">
                    <div className="flex items-center space-x-2">
                      {getCategoryIcon(type.category)}
                      <div>
                        <CardTitle className="text-lg">{type.manufacturer}</CardTitle>
                        <CardDescription>{type.model}</CardDescription>
                      </div>
                    </div>
                    <Badge variant="outline">{type.category}</Badge>
                  </div>
                </CardHeader>
                <CardContent className="space-y-4">
                  {/* Specifications */}
                  <div className="space-y-2">
                    <p className="text-xs font-medium text-slate-500 uppercase tracking-wide">
                      Key Specifications
                    </p>
                    <div className="grid grid-cols-2 gap-2 text-sm">
                      {Object.entries(type.specifications).slice(0, 4).map(([key, value]) => (
                        <div key={key}>
                          <p className="text-slate-500 capitalize">{key.replace('_', ' ')}</p>
                          <p className="font-medium">{value}</p>
                        </div>
                      ))}
                    </div>
                  </div>

                  {/* Warranty */}
                  <div className="flex items-center justify-between pt-2 border-t border-slate-200 dark:border-slate-700">
                    <div>
                      <p className="text-xs text-slate-500">Warranty</p>
                      <p className="text-sm font-medium">{type.warrantyYears} years</p>
                    </div>
                    <div className="flex items-center space-x-2">
                      <Button variant="outline" size="sm">
                        <Download className="h-3 w-3 mr-1" />
                        Datasheet
                      </Button>
                      <DropdownMenu>
                        <DropdownMenuTrigger asChild>
                          <Button variant="ghost" size="sm">
                            <MoreHorizontal className="h-4 w-4" />
                          </Button>
                        </DropdownMenuTrigger>
                        <DropdownMenuContent align="end">
                          <DropdownMenuItem>
                            <Edit className="mr-2 h-4 w-4" />
                            Edit Type
                          </DropdownMenuItem>
                          <DropdownMenuItem className="text-red-600">
                            <Trash2 className="mr-2 h-4 w-4" />
                            Delete Type
                          </DropdownMenuItem>
                        </DropdownMenuContent>
                      </DropdownMenu>
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </TabsContent>

        {/* Maintenance Tab */}
        <TabsContent value="maintenance" className="space-y-6">
          <div>
            <h2 className="text-2xl font-bold text-slate-900 dark:text-slate-100">Maintenance Schedule</h2>
            <p className="text-slate-600 dark:text-slate-400">Track and manage equipment maintenance</p>
          </div>

          {/* Maintenance Calendar/Schedule would go here */}
          <Card>
            <CardHeader>
              <CardTitle>Upcoming Maintenance</CardTitle>
              <CardDescription>Equipment requiring maintenance in the next 30 days</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {siteEquipment
                  .filter(eq => {
                    const nextDate = new Date(eq.nextMaintenanceDate);
                    const today = new Date();
                    const thirtyDaysFromNow = new Date(today.getTime() + 30 * 24 * 60 * 60 * 1000);
                    return nextDate <= thirtyDaysFromNow;
                  })
                  .map((equipment) => (
                    <div key={equipment.id} className="flex items-center justify-between p-4 border border-slate-200 dark:border-slate-700 rounded-lg">
                      <div className="flex items-center space-x-4">
                        {getCategoryIcon(equipment.equipmentType.category)}
                        <div>
                          <p className="font-medium text-slate-900 dark:text-slate-100">
                            {equipment.equipmentType.manufacturer} {equipment.equipmentType.model}
                          </p>
                          <p className="text-sm text-slate-500">{equipment.siteName}</p>
                          <p className="text-xs text-slate-500">Serial: {equipment.serialNumber}</p>
                        </div>
                      </div>
                      <div className="text-right">
                        <p className={`text-sm font-medium ${getMaintenanceStatusColor(equipment.nextMaintenanceDate)}`}>
                          {new Date(equipment.nextMaintenanceDate).toLocaleDateString()}
                        </p>
                        <p className="text-xs text-slate-500">{equipment.maintenanceSchedule}</p>
                      </div>
                      <Button size="sm">
                        <Calendar className="h-3 w-3 mr-1" />
                        Schedule
                      </Button>
                    </div>
                  ))}
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
};

export default HardwareManagement;