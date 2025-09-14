import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  AlertTriangle, 
  Bell, 
  CheckCircle, 
  XCircle, 
  Clock, 
  Filter, 
  Search, 
  Eye, 
  Trash2, 
  Settings,
  Zap,
  Thermometer,
  Battery,
  Wifi,
  Shield,
  Calendar,
  MapPin,
  User,
  RefreshCw
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { nexusApi, type Alert, type User, type Organization } from '@/services/nexusApi';
import { nexusTheme, getGlassStyle, getGradient } from '@/styles/nexusTheme';

interface AlertsManagementProps {
  user: User;
  organization: Organization;
  onBack: () => void;
}

const AlertsManagement: React.FC<AlertsManagementProps> = ({ user, organization, onBack }) => {
  const [alerts, setAlerts] = useState<Alert[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [severityFilter, setSeverityFilter] = useState<string>('all');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [selectedAlert, setSelectedAlert] = useState<Alert | null>(null);
  const [isViewDialogOpen, setIsViewDialogOpen] = useState(false);

  useEffect(() => {
    loadAlerts();
    
    // Set up WebSocket connection for real-time alerts
    const ws = nexusApi.connectWebSocket();
    if (ws) {
      ws.onmessage = (event) => {
        const data = JSON.parse(event.data);
        if (data.type === 'alert') {
          setAlerts(prev => [data.alert, ...prev]);
        }
      };
    }

    return () => {
      if (ws) {
        ws.close();
      }
    };
  }, [organization.id]);

  const loadAlerts = async () => {
    try {
      setLoading(true);
      const alertsData = await nexusApi.getAlerts(organization.id);
      setAlerts(alertsData);
    } catch (error) {
      console.error('Failed to load alerts:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleMarkAsRead = async (alertId: string) => {
    try {
      await nexusApi.markAlertAsRead(alertId);
      setAlerts(alerts.map(alert => 
        alert.id === alertId ? { ...alert, status: 'READ' } : alert
      ));
    } catch (error) {
      console.error('Failed to mark alert as read:', error);
    }
  };

  const handleResolveAlert = async (alertId: string) => {
    try {
      await nexusApi.resolveAlert(alertId);
      setAlerts(alerts.map(alert => 
        alert.id === alertId ? { ...alert, status: 'RESOLVED' } : alert
      ));
    } catch (error) {
      console.error('Failed to resolve alert:', error);
    }
  };

  const handleDeleteAlert = async (alertId: string) => {
    try {
      await nexusApi.deleteAlert(alertId);
      setAlerts(alerts.filter(alert => alert.id !== alertId));
    } catch (error) {
      console.error('Failed to delete alert:', error);
    }
  };

  const openViewDialog = (alert: Alert) => {
    setSelectedAlert(alert);
    setIsViewDialogOpen(true);
    if (alert.status === 'UNREAD') {
      handleMarkAsRead(alert.id);
    }
  };

  const filteredAlerts = alerts.filter(alert => {
    const matchesSearch = 
      alert.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
      alert.message.toLowerCase().includes(searchTerm.toLowerCase()) ||
      alert.siteName?.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesSeverity = severityFilter === 'all' || alert.severity === severityFilter;
    const matchesStatus = statusFilter === 'all' || alert.status === statusFilter;
    return matchesSearch && matchesSeverity && matchesStatus;
  });

  const getSeverityIcon = (severity: string) => {
    switch (severity) {
      case 'CRITICAL': return <XCircle className="w-4 h-4 text-red-500" />;
      case 'HIGH': return <AlertTriangle className="w-4 h-4 text-orange-500" />;
      case 'MEDIUM': return <Clock className="w-4 h-4 text-yellow-500" />;
      case 'LOW': return <CheckCircle className="w-4 h-4 text-blue-500" />;
      default: return <Bell className="w-4 h-4 text-gray-500" />;
    }
  };

  const getSeverityColor = (severity: string) => {
    switch (severity) {
      case 'CRITICAL': return 'bg-red-100 text-red-800 border-red-200';
      case 'HIGH': return 'bg-orange-100 text-orange-800 border-orange-200';
      case 'MEDIUM': return 'bg-yellow-100 text-yellow-800 border-yellow-200';
      case 'LOW': return 'bg-blue-100 text-blue-800 border-blue-200';
      default: return 'bg-gray-100 text-gray-800 border-gray-200';
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'UNREAD': return 'bg-red-100 text-red-800 border-red-200';
      case 'READ': return 'bg-blue-100 text-blue-800 border-blue-200';
      case 'RESOLVED': return 'bg-green-100 text-green-800 border-green-200';
      default: return 'bg-gray-100 text-gray-800 border-gray-200';
    }
  };

  const getAlertTypeIcon = (type: string) => {
    switch (type) {
      case 'SYSTEM': return <Settings className="w-4 h-4" />;
      case 'PERFORMANCE': return <Zap className="w-4 h-4" />;
      case 'MAINTENANCE': return <Thermometer className="w-4 h-4" />;
      case 'SECURITY': return <Shield className="w-4 h-4" />;
      case 'CONNECTIVITY': return <Wifi className="w-4 h-4" />;
      default: return <Bell className="w-4 h-4" />;
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
            <Bell className="w-8 h-8 text-white" />
          </motion.div>
          <h2 className="text-2xl font-bold bg-gradient-to-r from-green-600 to-blue-600 bg-clip-text text-transparent">
            Loading Alerts
          </h2>
          <p className="text-gray-600 mt-2">Fetching alert information...</p>
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
              Alerts & Notifications
            </h1>
            <p className="text-gray-600 mt-2">
              Monitor system alerts and notifications for {organization.name}
            </p>
          </div>
          <div className="flex gap-3">
            <Button
              onClick={loadAlerts}
              variant="outline"
              className="border-green-200 hover:border-green-300"
            >
              <RefreshCw className="w-4 h-4 mr-2" />
              Refresh
            </Button>
          </div>
        </div>
      </motion.div>

      {/* Stats Cards */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.1 }}
        className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-6"
      >
        <Card style={getGlassStyle()}>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600">Total Alerts</p>
                <p className="text-2xl font-bold text-gray-800">{alerts.length}</p>
              </div>
              <Bell className="w-8 h-8 text-blue-500" />
            </div>
          </CardContent>
        </Card>
        
        <Card style={getGlassStyle()}>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600">Unread</p>
                <p className="text-2xl font-bold text-gray-800">
                  {alerts.filter(a => a.status === 'UNREAD').length}
                </p>
              </div>
              <XCircle className="w-8 h-8 text-red-500" />
            </div>
          </CardContent>
        </Card>
        
        <Card style={getGlassStyle()}>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600">Critical</p>
                <p className="text-2xl font-bold text-gray-800">
                  {alerts.filter(a => a.severity === 'CRITICAL').length}
                </p>
              </div>
              <AlertTriangle className="w-8 h-8 text-red-500" />
            </div>
          </CardContent>
        </Card>
        
        <Card style={getGlassStyle()}>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600">Resolved</p>
                <p className="text-2xl font-bold text-gray-800">
                  {alerts.filter(a => a.status === 'RESOLVED').length}
                </p>
              </div>
              <CheckCircle className="w-8 h-8 text-green-500" />
            </div>
          </CardContent>
        </Card>
      </motion.div>

      {/* Filters and Search */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.2 }}
        className="mb-6"
      >
        <Card style={getGlassStyle()}>
          <CardContent className="p-4">
            <div className="flex flex-col md:flex-row gap-4">
              <div className="flex-1">
                <div className="relative">
                  <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4" />
                  <Input
                    placeholder="Search alerts by title, message, or site..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="pl-10"
                  />
                </div>
              </div>
              <div className="flex gap-2">
                <Select value={severityFilter} onValueChange={setSeverityFilter}>
                  <SelectTrigger className="w-40">
                    <SelectValue placeholder="Filter by severity" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All Severities</SelectItem>
                    <SelectItem value="CRITICAL">Critical</SelectItem>
                    <SelectItem value="HIGH">High</SelectItem>
                    <SelectItem value="MEDIUM">Medium</SelectItem>
                    <SelectItem value="LOW">Low</SelectItem>
                  </SelectContent>
                </Select>
                <Select value={statusFilter} onValueChange={setStatusFilter}>
                  <SelectTrigger className="w-40">
                    <SelectValue placeholder="Filter by status" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All Status</SelectItem>
                    <SelectItem value="UNREAD">Unread</SelectItem>
                    <SelectItem value="READ">Read</SelectItem>
                    <SelectItem value="RESOLVED">Resolved</SelectItem>
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

      {/* Alerts List */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.3 }}
        className="space-y-4"
      >
        {filteredAlerts.map((alert, index) => (
          <motion.div
            key={alert.id}
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: index * 0.05 }}
          >
            <Card 
              className={`hover:shadow-lg transition-all duration-300 cursor-pointer ${
                alert.status === 'UNREAD' ? 'ring-2 ring-blue-200' : ''
              }`}
              style={getGlassStyle()}
              onClick={() => openViewDialog(alert)}
            >
              <CardContent className="p-4">
                <div className="flex items-start justify-between">
                  <div className="flex items-start space-x-4 flex-1">
                    <div className="flex-shrink-0 mt-1">
                      {getAlertTypeIcon(alert.type)}
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-2">
                        <h3 className="text-lg font-semibold text-gray-800 truncate">
                          {alert.title}
                        </h3>
                        <Badge className={`${getSeverityColor(alert.severity)} border`}>
                          <div className="flex items-center gap-1">
                            {getSeverityIcon(alert.severity)}
                            {alert.severity}
                          </div>
                        </Badge>
                        <Badge className={`${getStatusColor(alert.status)} border`}>
                          {alert.status}
                        </Badge>
                      </div>
                      <p className="text-gray-600 mb-2 line-clamp-2">
                        {alert.message}
                      </p>
                      <div className="flex items-center gap-4 text-sm text-gray-500">
                        {alert.siteName && (
                          <div className="flex items-center">
                            <MapPin className="w-3 h-3 mr-1" />
                            {alert.siteName}
                          </div>
                        )}
                        <div className="flex items-center">
                          <Calendar className="w-3 h-3 mr-1" />
                          {new Date(alert.created_at).toLocaleString()}
                        </div>
                      </div>
                    </div>
                  </div>
                  <div className="flex items-center gap-2 ml-4">
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={(e) => {
                        e.stopPropagation();
                        openViewDialog(alert);
                      }}
                    >
                      <Eye className="w-3 h-3" />
                    </Button>
                    {alert.status !== 'RESOLVED' && (
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={(e) => {
                          e.stopPropagation();
                          handleResolveAlert(alert.id);
                        }}
                        className="text-green-600 hover:text-green-700 hover:bg-green-50"
                      >
                        <CheckCircle className="w-3 h-3" />
                      </Button>
                    )}
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={(e) => {
                        e.stopPropagation();
                        handleDeleteAlert(alert.id);
                      }}
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
      {filteredAlerts.length === 0 && !loading && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          className="text-center py-12"
        >
          <Bell className="w-16 h-16 text-gray-400 mx-auto mb-4" />
          <h3 className="text-xl font-semibold text-gray-600 mb-2">
            {searchTerm || severityFilter !== 'all' || statusFilter !== 'all' 
              ? 'No alerts match your filters' 
              : 'No alerts yet'
            }
          </h3>
          <p className="text-gray-500">
            {searchTerm || severityFilter !== 'all' || statusFilter !== 'all'
              ? 'Try adjusting your search or filter criteria'
              : 'All systems are running smoothly!'
            }
          </p>
        </motion.div>
      )}

      {/* View Alert Dialog */}
      <Dialog open={isViewDialogOpen} onOpenChange={setIsViewDialogOpen}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>Alert Details</DialogTitle>
            <DialogDescription>
              View detailed information about this alert.
            </DialogDescription>
          </DialogHeader>
          {selectedAlert && (
            <div className="space-y-6">
              <div className="flex items-start justify-between">
                <div>
                  <h3 className="text-xl font-semibold mb-2">{selectedAlert.title}</h3>
                  <div className="flex gap-2 mb-4">
                    <Badge className={`${getSeverityColor(selectedAlert.severity)} border`}>
                      <div className="flex items-center gap-1">
                        {getSeverityIcon(selectedAlert.severity)}
                        {selectedAlert.severity}
                      </div>
                    </Badge>
                    <Badge className={`${getStatusColor(selectedAlert.status)} border`}>
                      {selectedAlert.status}
                    </Badge>
                  </div>
                </div>
                <div className="flex items-center">
                  {getAlertTypeIcon(selectedAlert.type)}
                  <span className="ml-2 text-sm text-gray-600">{selectedAlert.type}</span>
                </div>
              </div>

              <div>
                <h4 className="font-semibold text-gray-700 mb-2">Message</h4>
                <p className="text-gray-600 bg-gray-50 p-3 rounded-lg">
                  {selectedAlert.message}
                </p>
              </div>

              <div className="grid grid-cols-2 gap-6">
                <div>
                  <h4 className="font-semibold text-gray-700 mb-2">Alert Information</h4>
                  <div className="space-y-2 text-sm">
                    {selectedAlert.siteName && (
                      <div className="flex items-center">
                        <MapPin className="w-4 h-4 mr-2 text-gray-500" />
                        Site: {selectedAlert.siteName}
                      </div>
                    )}
                    <div className="flex items-center">
                      <Calendar className="w-4 h-4 mr-2 text-gray-500" />
                      Created: {new Date(selectedAlert.created_at).toLocaleString()}
                    </div>
                    {selectedAlert.resolved_at && (
                      <div className="flex items-center">
                        <CheckCircle className="w-4 h-4 mr-2 text-gray-500" />
                        Resolved: {new Date(selectedAlert.resolved_at).toLocaleString()}
                      </div>
                    )}
                  </div>
                </div>

                {selectedAlert.metadata && (
                  <div>
                    <h4 className="font-semibold text-gray-700 mb-2">Additional Details</h4>
                    <div className="text-sm text-gray-600 bg-gray-50 p-3 rounded-lg">
                      <pre className="whitespace-pre-wrap">
                        {JSON.stringify(selectedAlert.metadata, null, 2)}
                      </pre>
                    </div>
                  </div>
                )}
              </div>

              <div className="flex justify-end gap-3">
                {selectedAlert.status !== 'RESOLVED' && (
                  <Button 
                    onClick={() => {
                      handleResolveAlert(selectedAlert.id);
                      setIsViewDialogOpen(false);
                    }}
                    className="bg-green-500 hover:bg-green-600 text-white"
                  >
                    <CheckCircle className="w-4 h-4 mr-2" />
                    Mark as Resolved
                  </Button>
                )}
                <Button variant="outline" onClick={() => setIsViewDialogOpen(false)}>
                  Close
                </Button>
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
};

export default AlertsManagement;