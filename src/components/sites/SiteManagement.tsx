import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  MapPin, 
  Plus, 
  Edit, 
  Trash2, 
  Eye, 
  Activity, 
  AlertTriangle, 
  CheckCircle, 
  XCircle,
  Settings,
  BarChart3,
  Calendar,
  Zap,
  Sun,
  Battery,
  TrendingUp,
  Search,
  Filter,
  Download,
  Upload
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Textarea } from '@/components/ui/textarea';
import { Progress } from '@/components/ui/progress';
import { nexusApi, type Site, type User, type Organization } from '@/services/nexusApi';
import { nexusTheme, getGlassStyle, getGradient } from '@/styles/nexusTheme';

interface SiteManagementProps {
  user: User;
  organization: Organization;
  onBack: () => void;
}

const SiteManagement: React.FC<SiteManagementProps> = ({ user, organization, onBack }) => {
  const [sites, setSites] = useState<Site[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [selectedSite, setSelectedSite] = useState<Site | null>(null);
  const [isCreateDialogOpen, setIsCreateDialogOpen] = useState(false);
  const [isEditDialogOpen, setIsEditDialogOpen] = useState(false);
  const [isDeleteDialogOpen, setIsDeleteDialogOpen] = useState(false);

  // Form state for create/edit
  const [formData, setFormData] = useState({
    name: '',
    address: '',
    city: '',
    country: 'South Africa',
    latitude: 0,
    longitude: 0,
    capacity: 0,
    systemType: 'GRID_TIED' as const,
    panelCount: 0,
    inverterType: '',
    installationDate: ''
  });

  useEffect(() => {
    loadSites();
  }, [organization.id]);

  const loadSites = async () => {
    try {
      setLoading(true);
      const sitesData = await nexusApi.getSites(organization.id);
      setSites(sitesData);
    } catch (error) {
      console.error('Failed to load sites:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleCreateSite = async () => {
    try {
      const newSite = await nexusApi.createSite({
        ...formData,
        organizationId: organization.id,
        location: {
          latitude: formData.latitude,
          longitude: formData.longitude,
          address: formData.address,
          city: formData.city,
          country: formData.country
        },
        status: 'ACTIVE',
        performanceRatio: 85,
        isActive: true
      });
      
      setSites([...sites, newSite]);
      setIsCreateDialogOpen(false);
      resetForm();
    } catch (error) {
      console.error('Failed to create site:', error);
    }
  };

  const handleUpdateSite = async () => {
    if (!selectedSite) return;

    try {
      const updatedSite = await nexusApi.updateSite(selectedSite.id, {
        ...formData,
        location: {
          latitude: formData.latitude,
          longitude: formData.longitude,
          address: formData.address,
          city: formData.city,
          country: formData.country
        }
      });
      
      setSites(sites.map(site => site.id === selectedSite.id ? updatedSite : site));
      setIsEditDialogOpen(false);
      setSelectedSite(null);
      resetForm();
    } catch (error) {
      console.error('Failed to update site:', error);
    }
  };

  const handleDeleteSite = async () => {
    if (!selectedSite) return;

    try {
      await nexusApi.deleteSite(selectedSite.id);
      setSites(sites.filter(site => site.id !== selectedSite.id));
      setIsDeleteDialogOpen(false);
      setSelectedSite(null);
    } catch (error) {
      console.error('Failed to delete site:', error);
    }
  };

  const resetForm = () => {
    setFormData({
      name: '',
      address: '',
      city: '',
      country: 'South Africa',
      latitude: 0,
      longitude: 0,
      capacity: 0,
      systemType: 'GRID_TIED',
      panelCount: 0,
      inverterType: '',
      installationDate: ''
    });
  };

  const openEditDialog = (site: Site) => {
    setSelectedSite(site);
    setFormData({
      name: site.name,
      address: site.location.address,
      city: site.location.city,
      country: site.location.country,
      latitude: site.location.latitude,
      longitude: site.location.longitude,
      capacity: site.capacity,
      systemType: site.systemType,
      panelCount: site.panelCount,
      inverterType: site.inverterType,
      installationDate: site.installationDate.split('T')[0]
    });
    setIsEditDialogOpen(true);
  };

  const openDeleteDialog = (site: Site) => {
    setSelectedSite(site);
    setIsDeleteDialogOpen(true);
  };

  const filteredSites = sites.filter(site => {
    const matchesSearch = site.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         site.location.city.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesStatus = statusFilter === 'all' || site.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'ACTIVE': return <CheckCircle className="w-4 h-4 text-green-500" />;
      case 'MAINTENANCE': return <Settings className="w-4 h-4 text-yellow-500" />;
      case 'OFFLINE': return <XCircle className="w-4 h-4 text-red-500" />;
      case 'FAULT': return <AlertTriangle className="w-4 h-4 text-red-500" />;
      default: return <Activity className="w-4 h-4 text-gray-500" />;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'ACTIVE': return 'bg-green-100 text-green-800 border-green-200';
      case 'MAINTENANCE': return 'bg-yellow-100 text-yellow-800 border-yellow-200';
      case 'OFFLINE': return 'bg-red-100 text-red-800 border-red-200';
      case 'FAULT': return 'bg-red-100 text-red-800 border-red-200';
      default: return 'bg-gray-100 text-gray-800 border-gray-200';
    }
  };

  if (loading) {
    return (
      <div 
        className="min-h-screen flex items-center justify-center"
        style={{ background: getGradient('lightBg') }}
      >
        <motion.div
          initial={{ opacity: 0, scale: 0.5 }}
          animate={{ opacity: 1, scale: 1 }}
          className="text-center"
        >
          <motion.div
            animate={{ rotate: 360 }}
            transition={{ duration: 2, repeat: Infinity, ease: "linear" }}
            className="w-16 h-16 mx-auto mb-4 rounded-full bg-gradient-to-r from-green-500 to-blue-500 flex items-center justify-center"
          >
            <Sun className="w-8 h-8 text-white" />
          </motion.div>
          <h2 className="text-2xl font-bold bg-gradient-to-r from-green-600 to-blue-600 bg-clip-text text-transparent">
            Loading Sites
          </h2>
          <p className="text-gray-600 mt-2">Fetching site information...</p>
        </motion.div>
      </div>
    );
  }

  return (
    <div 
      className="min-h-screen p-6"
      style={{ background: getGradient('lightBg') }}
    >
      {/* Header */}
      <motion.div
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        className="mb-8"
      >
        <div className="flex items-center justify-between">
          <div>
            <Button
              variant="ghost"
              onClick={onBack}
              className="mb-4 text-gray-600 hover:text-gray-800"
            >
              ← Back to Dashboard
            </Button>
            <h1 className="text-4xl font-bold bg-gradient-to-r from-green-600 to-blue-600 bg-clip-text text-transparent">
              Site Management
            </h1>
            <p className="text-gray-600 mt-2">
              Manage your solar installations and monitor performance
            </p>
          </div>
          <div className="flex gap-3">
            <Button
              onClick={() => setIsCreateDialogOpen(true)}
              className="bg-gradient-to-r from-green-500 to-blue-500 hover:from-green-600 hover:to-blue-600 text-white"
            >
              <Plus className="w-4 h-4 mr-2" />
              Add Site
            </Button>
          </div>
        </div>
      </motion.div>

      {/* Filters and Search */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.1 }}
        className="mb-6"
      >
        <Card style={getGlassStyle()}>
          <CardContent className="p-4">
            <div className="flex flex-col md:flex-row gap-4">
              <div className="flex-1">
                <div className="relative">
                  <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4" />
                  <Input
                    placeholder="Search sites by name or location..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="pl-10"
                  />
                </div>
              </div>
              <div className="flex gap-2">
                <Select value={statusFilter} onValueChange={setStatusFilter}>
                  <SelectTrigger className="w-40">
                    <SelectValue placeholder="Filter by status" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All Status</SelectItem>
                    <SelectItem value="ACTIVE">Active</SelectItem>
                    <SelectItem value="MAINTENANCE">Maintenance</SelectItem>
                    <SelectItem value="OFFLINE">Offline</SelectItem>
                    <SelectItem value="FAULT">Fault</SelectItem>
                  </SelectContent>
                </Select>
                <Button variant="outline" size="icon">
                  <Filter className="w-4 h-4" />
                </Button>
              </div>
            </div>
          </CardContent>
        </Card>
      </motion.div>

      {/* Sites Grid */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.2 }}
        className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6"
      >
        {filteredSites.map((site, index) => (
          <motion.div
            key={site.id}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: index * 0.1 }}
          >
            <Card 
              className="h-full hover:shadow-lg transition-all duration-300 cursor-pointer group"
              style={getGlassStyle()}
            >
              <CardHeader className="pb-3">
                <div className="flex items-start justify-between">
                  <div>
                    <CardTitle className="text-lg font-semibold text-gray-800 group-hover:text-green-600 transition-colors">
                      {site.name}
                    </CardTitle>
                    <CardDescription className="flex items-center mt-1">
                      <MapPin className="w-3 h-3 mr-1" />
                      {site.location.city}, {site.location.country}
                    </CardDescription>
                  </div>
                  <Badge className={`${getStatusColor(site.status)} border`}>
                    <div className="flex items-center gap-1">
                      {getStatusIcon(site.status)}
                      {site.status}
                    </div>
                  </Badge>
                </div>
              </CardHeader>
              <CardContent>
                <div className="space-y-3">
                  {/* Key Metrics */}
                  <div className="grid grid-cols-2 gap-3">
                    <div className="text-center p-2 bg-white/50 rounded-lg">
                      <div className="flex items-center justify-center mb-1">
                        <Zap className="w-4 h-4 text-yellow-500 mr-1" />
                        <span className="text-xs text-gray-600">Capacity</span>
                      </div>
                      <div className="font-semibold text-gray-800">{site.capacity} kW</div>
                    </div>
                    <div className="text-center p-2 bg-white/50 rounded-lg">
                      <div className="flex items-center justify-center mb-1">
                        <TrendingUp className="w-4 h-4 text-green-500 mr-1" />
                        <span className="text-xs text-gray-600">Performance</span>
                      </div>
                      <div className="font-semibold text-gray-800">{site.performanceRatio}%</div>
                    </div>
                  </div>

                  {/* Performance Bar */}
                  <div>
                    <div className="flex justify-between text-xs text-gray-600 mb-1">
                      <span>Performance Ratio</span>
                      <span>{site.performanceRatio}%</span>
                    </div>
                    <Progress value={site.performanceRatio} className="h-2" />
                  </div>

                  {/* System Info */}
                  <div className="text-xs text-gray-600 space-y-1">
                    <div className="flex justify-between">
                      <span>System Type:</span>
                      <span className="font-medium">{site.systemType.replace('_', ' ')}</span>
                    </div>
                    <div className="flex justify-between">
                      <span>Panels:</span>
                      <span className="font-medium">{site.panelCount}</span>
                    </div>
                    <div className="flex justify-between">
                      <span>Installed:</span>
                      <span className="font-medium">
                        {new Date(site.installationDate).toLocaleDateString()}
                      </span>
                    </div>
                  </div>

                  {/* Action Buttons */}
                  <div className="flex gap-2 pt-2">
                    <Button
                      variant="outline"
                      size="sm"
                      className="flex-1"
                      onClick={() => openEditDialog(site)}
                    >
                      <Edit className="w-3 h-3 mr-1" />
                      Edit
                    </Button>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => openDeleteDialog(site)}
                      className="text-red-600 hover:text-red-700 hover:bg-red-50"
                    >
                      <Trash2 className="w-3 h-3" />
                    </Button>
                  </div>
                </div>
              </CardContent>
            </Card>
          </motion.div>
        ))}
      </motion.div>

      {/* Empty State */}
      {filteredSites.length === 0 && !loading && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          className="text-center py-12"
        >
          <Sun className="w-16 h-16 text-gray-400 mx-auto mb-4" />
          <h3 className="text-xl font-semibold text-gray-600 mb-2">
            {searchTerm || statusFilter !== 'all' ? 'No sites match your filters' : 'No sites yet'}
          </h3>
          <p className="text-gray-500 mb-6">
            {searchTerm || statusFilter !== 'all' 
              ? 'Try adjusting your search or filter criteria'
              : 'Get started by adding your first solar installation'
            }
          </p>
          {!searchTerm && statusFilter === 'all' && (
            <Button
              onClick={() => setIsCreateDialogOpen(true)}
              className="bg-gradient-to-r from-green-500 to-blue-500 hover:from-green-600 hover:to-blue-600 text-white"
            >
              <Plus className="w-4 h-4 mr-2" />
              Add Your First Site
            </Button>
          )}
        </motion.div>
      )}

      {/* Create Site Dialog */}
      <Dialog open={isCreateDialogOpen} onOpenChange={setIsCreateDialogOpen}>
        <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>Add New Site</DialogTitle>
            <DialogDescription>
              Create a new solar installation site for monitoring and management.
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label htmlFor="name">Site Name</Label>
                <Input
                  id="name"
                  value={formData.name}
                  onChange={(e) => setFormData({...formData, name: e.target.value})}
                  placeholder="e.g., Cape Town Solar Farm"
                />
              </div>
              <div>
                <Label htmlFor="capacity">Capacity (kW)</Label>
                <Input
                  id="capacity"
                  type="number"
                  value={formData.capacity}
                  onChange={(e) => setFormData({...formData, capacity: parseFloat(e.target.value) || 0})}
                  placeholder="100"
                />
              </div>
            </div>
            
            <div>
              <Label htmlFor="address">Address</Label>
              <Input
                id="address"
                value={formData.address}
                onChange={(e) => setFormData({...formData, address: e.target.value})}
                placeholder="123 Solar Street"
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label htmlFor="city">City</Label>
                <Input
                  id="city"
                  value={formData.city}
                  onChange={(e) => setFormData({...formData, city: e.target.value})}
                  placeholder="Cape Town"
                />
              </div>
              <div>
                <Label htmlFor="country">Country</Label>
                <Select value={formData.country} onValueChange={(value) => setFormData({...formData, country: value})}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="South Africa">South Africa</SelectItem>
                    <SelectItem value="Kenya">Kenya</SelectItem>
                    <SelectItem value="Nigeria">Nigeria</SelectItem>
                    <SelectItem value="Ghana">Ghana</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label htmlFor="latitude">Latitude</Label>
                <Input
                  id="latitude"
                  type="number"
                  step="any"
                  value={formData.latitude}
                  onChange={(e) => setFormData({...formData, latitude: parseFloat(e.target.value) || 0})}
                  placeholder="-33.9249"
                />
              </div>
              <div>
                <Label htmlFor="longitude">Longitude</Label>
                <Input
                  id="longitude"
                  type="number"
                  step="any"
                  value={formData.longitude}
                  onChange={(e) => setFormData({...formData, longitude: parseFloat(e.target.value) || 0})}
                  placeholder="18.4241"
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label htmlFor="systemType">System Type</Label>
                <Select value={formData.systemType} onValueChange={(value: any) => setFormData({...formData, systemType: value})}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="GRID_TIED">Grid Tied</SelectItem>
                    <SelectItem value="OFF_GRID">Off Grid</SelectItem>
                    <SelectItem value="HYBRID">Hybrid</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div>
                <Label htmlFor="panelCount">Panel Count</Label>
                <Input
                  id="panelCount"
                  type="number"
                  value={formData.panelCount}
                  onChange={(e) => setFormData({...formData, panelCount: parseInt(e.target.value) || 0})}
                  placeholder="400"
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label htmlFor="inverterType">Inverter Type</Label>
                <Input
                  id="inverterType"
                  value={formData.inverterType}
                  onChange={(e) => setFormData({...formData, inverterType: e.target.value})}
                  placeholder="SolarEdge SE100K"
                />
              </div>
              <div>
                <Label htmlFor="installationDate">Installation Date</Label>
                <Input
                  id="installationDate"
                  type="date"
                  value={formData.installationDate}
                  onChange={(e) => setFormData({...formData, installationDate: e.target.value})}
                />
              </div>
            </div>

            <div className="flex justify-end gap-3 pt-4">
              <Button variant="outline" onClick={() => setIsCreateDialogOpen(false)}>
                Cancel
              </Button>
              <Button 
                onClick={handleCreateSite}
                className="bg-gradient-to-r from-green-500 to-blue-500 hover:from-green-600 hover:to-blue-600 text-white"
              >
                Create Site
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>

      {/* Edit Site Dialog */}
      <Dialog open={isEditDialogOpen} onOpenChange={setIsEditDialogOpen}>
        <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>Edit Site</DialogTitle>
            <DialogDescription>
              Update the site information and configuration.
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            {/* Same form fields as create dialog */}
            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label htmlFor="edit-name">Site Name</Label>
                <Input
                  id="edit-name"
                  value={formData.name}
                  onChange={(e) => setFormData({...formData, name: e.target.value})}
                />
              </div>
              <div>
                <Label htmlFor="edit-capacity">Capacity (kW)</Label>
                <Input
                  id="edit-capacity"
                  type="number"
                  value={formData.capacity}
                  onChange={(e) => setFormData({...formData, capacity: parseFloat(e.target.value) || 0})}
                />
              </div>
            </div>
            
            <div>
              <Label htmlFor="edit-address">Address</Label>
              <Input
                id="edit-address"
                value={formData.address}
                onChange={(e) => setFormData({...formData, address: e.target.value})}
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label htmlFor="edit-city">City</Label>
                <Input
                  id="edit-city"
                  value={formData.city}
                  onChange={(e) => setFormData({...formData, city: e.target.value})}
                />
              </div>
              <div>
                <Label htmlFor="edit-country">Country</Label>
                <Select value={formData.country} onValueChange={(value) => setFormData({...formData, country: value})}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="South Africa">South Africa</SelectItem>
                    <SelectItem value="Kenya">Kenya</SelectItem>
                    <SelectItem value="Nigeria">Nigeria</SelectItem>
                    <SelectItem value="Ghana">Ghana</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>

            <div className="flex justify-end gap-3 pt-4">
              <Button variant="outline" onClick={() => setIsEditDialogOpen(false)}>
                Cancel
              </Button>
              <Button 
                onClick={handleUpdateSite}
                className="bg-gradient-to-r from-green-500 to-blue-500 hover:from-green-600 hover:to-blue-600 text-white"
              >
                Update Site
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation Dialog */}
      <Dialog open={isDeleteDialogOpen} onOpenChange={setIsDeleteDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Delete Site</DialogTitle>
            <DialogDescription>
              Are you sure you want to delete "{selectedSite?.name}"? This action cannot be undone.
            </DialogDescription>
          </DialogHeader>
          <div className="flex justify-end gap-3 pt-4">
            <Button variant="outline" onClick={() => setIsDeleteDialogOpen(false)}>
              Cancel
            </Button>
            <Button 
              onClick={handleDeleteSite}
              variant="destructive"
            >
              Delete Site
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
};

export default SiteManagement;