import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../../../components/ui/card';
import { Button } from '../../../components/ui/button';
import { Badge } from '../../../components/ui/badge';
import { Input } from '../../../components/ui/input';
import { Label } from '../../../components/ui/label';
import { Textarea } from '../../../components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../../../components/ui/select';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from '../../../components/ui/dialog';
import { Checkbox } from '../../../components/ui/checkbox';
import { 
  Plus, 
  Search, 
  Filter, 
  MoreHorizontal, 
  Edit, 
  Trash2, 
  Eye,
  Users,
  Shield,
  Mail,
  Phone,
  Building,
  Calendar,
  CheckCircle,
  XCircle,
  AlertTriangle,
  Key,
  UserPlus
} from 'lucide-react';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '../../../components/ui/dropdown-menu';
import { UserRole } from '../../../contexts/MultiPortalAuthContext';

// Mock data - replace with actual API calls
const mockUsers = [
  {
    id: 1,
    email: 'admin@nexusgreen.energy',
    firstName: 'System',
    lastName: 'Administrator',
    phone: '+27 11 123 4567',
    company: 'NexusGreen Energy',
    title: 'System Administrator',
    isActive: true,
    emailVerified: true,
    lastLogin: '2024-09-16T14:30:00Z',
    createdAt: '2024-01-01T00:00:00Z',
    roles: [
      { roleName: UserRole.SUPER_ADMIN, projectId: null, siteId: null, projectName: null, siteName: null }
    ]
  },
  {
    id: 2,
    email: 'john.smith@abc-mfg.com',
    firstName: 'John',
    lastName: 'Smith',
    phone: '+27 21 987 6543',
    company: 'ABC Manufacturing',
    title: 'Facilities Manager',
    isActive: true,
    emailVerified: true,
    lastLogin: '2024-09-16T10:15:00Z',
    createdAt: '2024-02-15T00:00:00Z',
    roles: [
      { roleName: UserRole.CUSTOMER, projectId: 1, siteId: null, projectName: 'Solar Farm Alpha', siteName: null }
    ]
  },
  {
    id: 3,
    email: 'sarah.johnson@greenfund.com',
    firstName: 'Sarah',
    lastName: 'Johnson',
    phone: '+27 31 555 0123',
    company: 'Green Energy Fund',
    title: 'Investment Manager',
    isActive: true,
    emailVerified: true,
    lastLogin: '2024-09-15T16:45:00Z',
    createdAt: '2024-01-20T00:00:00Z',
    roles: [
      { roleName: UserRole.FUNDER, projectId: 1, siteId: null, projectName: 'Solar Farm Alpha', siteName: null },
      { roleName: UserRole.FUNDER, projectId: 2, siteId: null, projectName: 'Corporate Rooftop Initiative', siteName: null }
    ]
  },
  {
    id: 4,
    email: 'mike.wilson@solartech.com',
    firstName: 'Mike',
    lastName: 'Wilson',
    phone: '+27 11 444 5678',
    company: 'SolarTech O&M',
    title: 'Operations Manager',
    isActive: true,
    emailVerified: false,
    lastLogin: '2024-09-14T08:30:00Z',
    createdAt: '2024-03-01T00:00:00Z',
    roles: [
      { roleName: UserRole.OM_PROVIDER, projectId: null, siteId: 1, projectName: null, siteName: 'Johannesburg Office Complex' },
      { roleName: UserRole.OM_PROVIDER, projectId: null, siteId: 2, projectName: null, siteName: 'Cape Town Manufacturing Plant' }
    ]
  },
  {
    id: 5,
    email: 'inactive.user@example.com',
    firstName: 'Inactive',
    lastName: 'User',
    phone: '+27 21 000 0000',
    company: 'Former Company',
    title: 'Former Employee',
    isActive: false,
    emailVerified: true,
    lastLogin: '2024-08-01T12:00:00Z',
    createdAt: '2024-01-15T00:00:00Z',
    roles: []
  }
];

const mockProjects = [
  { id: 1, name: 'Solar Farm Alpha', code: 'SFA-001' },
  { id: 2, name: 'Corporate Rooftop Initiative', code: 'CRI-002' },
  { id: 3, name: 'Community Solar Garden', code: 'CSG-003' }
];

const mockSites = [
  { id: 1, name: 'Johannesburg Office Complex', code: 'JHB-001', projectId: 1 },
  { id: 2, name: 'Cape Town Manufacturing Plant', code: 'CPT-002', projectId: 1 },
  { id: 3, name: 'Durban Warehouse Facility', code: 'DBN-003', projectId: 2 }
];

const UserManagement: React.FC = () => {
  const [users, setUsers] = useState(mockUsers);
  const [filteredUsers, setFilteredUsers] = useState(mockUsers);
  const [searchTerm, setSearchTerm] = useState('');
  const [roleFilter, setRoleFilter] = useState('ALL');
  const [statusFilter, setStatusFilter] = useState('ALL');
  const [isCreateDialogOpen, setIsCreateDialogOpen] = useState(false);
  const [isEditDialogOpen, setIsEditDialogOpen] = useState(false);
  const [isRoleDialogOpen, setIsRoleDialogOpen] = useState(false);
  const [selectedUser, setSelectedUser] = useState<any>(null);
  const [newUserForm, setNewUserForm] = useState({
    email: '',
    firstName: '',
    lastName: '',
    phone: '',
    company: '',
    title: '',
    roles: [] as any[]
  });

  // Filter users based on search and filters
  useEffect(() => {
    let filtered = users;

    if (searchTerm) {
      filtered = filtered.filter(user =>
        user.firstName.toLowerCase().includes(searchTerm.toLowerCase()) ||
        user.lastName.toLowerCase().includes(searchTerm.toLowerCase()) ||
        user.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
        user.company.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }

    if (roleFilter !== 'ALL') {
      filtered = filtered.filter(user =>
        user.roles.some(role => role.roleName === roleFilter)
      );
    }

    if (statusFilter !== 'ALL') {
      if (statusFilter === 'ACTIVE') {
        filtered = filtered.filter(user => user.isActive);
      } else if (statusFilter === 'INACTIVE') {
        filtered = filtered.filter(user => !user.isActive);
      } else if (statusFilter === 'UNVERIFIED') {
        filtered = filtered.filter(user => !user.emailVerified);
      }
    }

    setFilteredUsers(filtered);
  }, [users, searchTerm, roleFilter, statusFilter]);

  const getRoleColor = (role: UserRole) => {
    switch (role) {
      case UserRole.SUPER_ADMIN: return 'bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-300';
      case UserRole.CUSTOMER: return 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300';
      case UserRole.FUNDER: return 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300';
      case UserRole.OM_PROVIDER: return 'bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-300';
      default: return 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-300';
    }
  };

  const getRoleIcon = (role: UserRole) => {
    switch (role) {
      case UserRole.SUPER_ADMIN: return <Shield className="h-3 w-3" />;
      case UserRole.CUSTOMER: return <Users className="h-3 w-3" />;
      case UserRole.FUNDER: return <Building className="h-3 w-3" />;
      case UserRole.OM_PROVIDER: return <Key className="h-3 w-3" />;
      default: return <Users className="h-3 w-3" />;
    }
  };

  const handleCreateUser = () => {
    // Handle user creation
    const newUser = {
      id: users.length + 1,
      ...newUserForm,
      isActive: true,
      emailVerified: false,
      lastLogin: null,
      createdAt: new Date().toISOString()
    };
    setUsers([...users, newUser]);
    setIsCreateDialogOpen(false);
    setNewUserForm({
      email: '',
      firstName: '',
      lastName: '',
      phone: '',
      company: '',
      title: '',
      roles: []
    });
  };

  const handleEditUser = (user: any) => {
    setSelectedUser(user);
    setIsEditDialogOpen(true);
  };

  const handleManageRoles = (user: any) => {
    setSelectedUser(user);
    setIsRoleDialogOpen(true);
  };

  const handleToggleUserStatus = (userId: number) => {
    setUsers(users.map(user => 
      user.id === userId ? { ...user, isActive: !user.isActive } : user
    ));
  };

  const handleDeleteUser = (userId: number) => {
    if (confirm('Are you sure you want to delete this user? This action cannot be undone.')) {
      setUsers(users.filter(u => u.id !== userId));
    }
  };

  const handleSendPasswordReset = (userEmail: string) => {
    // Handle password reset
    alert(`Password reset email sent to ${userEmail}`);
  };

  return (
    <div className="px-4 sm:px-6 lg:px-8">
      {/* Header */}
      <div className="mb-8">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold text-slate-900 dark:text-slate-100">
              User Management
            </h1>
            <p className="mt-2 text-slate-600 dark:text-slate-400">
              Manage user accounts, roles, and access permissions
            </p>
          </div>
          <Dialog open={isCreateDialogOpen} onOpenChange={setIsCreateDialogOpen}>
            <DialogTrigger asChild>
              <Button>
                <UserPlus className="h-4 w-4 mr-2" />
                Add User
              </Button>
            </DialogTrigger>
            <DialogContent className="max-w-2xl">
              <DialogHeader>
                <DialogTitle>Create New User</DialogTitle>
                <DialogDescription>
                  Add a new user to the system and assign roles
                </DialogDescription>
              </DialogHeader>
              <div className="grid grid-cols-2 gap-4 py-4">
                <div className="space-y-2">
                  <Label htmlFor="firstName">First Name</Label>
                  <Input 
                    id="firstName" 
                    value={newUserForm.firstName}
                    onChange={(e) => setNewUserForm({...newUserForm, firstName: e.target.value})}
                    placeholder="John" 
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="lastName">Last Name</Label>
                  <Input 
                    id="lastName" 
                    value={newUserForm.lastName}
                    onChange={(e) => setNewUserForm({...newUserForm, lastName: e.target.value})}
                    placeholder="Smith" 
                  />
                </div>
                <div className="col-span-2 space-y-2">
                  <Label htmlFor="email">Email Address</Label>
                  <Input 
                    id="email" 
                    type="email"
                    value={newUserForm.email}
                    onChange={(e) => setNewUserForm({...newUserForm, email: e.target.value})}
                    placeholder="john.smith@company.com" 
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="phone">Phone Number</Label>
                  <Input 
                    id="phone" 
                    value={newUserForm.phone}
                    onChange={(e) => setNewUserForm({...newUserForm, phone: e.target.value})}
                    placeholder="+27 11 123 4567" 
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="title">Job Title</Label>
                  <Input 
                    id="title" 
                    value={newUserForm.title}
                    onChange={(e) => setNewUserForm({...newUserForm, title: e.target.value})}
                    placeholder="Facilities Manager" 
                  />
                </div>
                <div className="col-span-2 space-y-2">
                  <Label htmlFor="company">Company</Label>
                  <Input 
                    id="company" 
                    value={newUserForm.company}
                    onChange={(e) => setNewUserForm({...newUserForm, company: e.target.value})}
                    placeholder="ABC Manufacturing" 
                  />
                </div>
                <div className="col-span-2 space-y-2">
                  <Label>Initial Role</Label>
                  <Select>
                    <SelectTrigger>
                      <SelectValue placeholder="Select initial role" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="CUSTOMER">Customer</SelectItem>
                      <SelectItem value="FUNDER">Funder</SelectItem>
                      <SelectItem value="OM_PROVIDER">O&M Provider</SelectItem>
                      <SelectItem value="SUPER_ADMIN">Super Admin</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>
              <DialogFooter>
                <Button variant="outline" onClick={() => setIsCreateDialogOpen(false)}>
                  Cancel
                </Button>
                <Button onClick={handleCreateUser}>Create User</Button>
              </DialogFooter>
            </DialogContent>
          </Dialog>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-slate-600 dark:text-slate-400">Total Users</p>
                <p className="text-3xl font-bold text-slate-900 dark:text-slate-100">{users.length}</p>
              </div>
              <Users className="h-8 w-8 text-blue-600" />
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-slate-600 dark:text-slate-400">Active Users</p>
                <p className="text-3xl font-bold text-slate-900 dark:text-slate-100">
                  {users.filter(u => u.isActive).length}
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
                <p className="text-sm font-medium text-slate-600 dark:text-slate-400">Unverified</p>
                <p className="text-3xl font-bold text-slate-900 dark:text-slate-100">
                  {users.filter(u => !u.emailVerified).length}
                </p>
              </div>
              <AlertTriangle className="h-8 w-8 text-orange-600" />
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-slate-600 dark:text-slate-400">Inactive</p>
                <p className="text-3xl font-bold text-slate-900 dark:text-slate-100">
                  {users.filter(u => !u.isActive).length}
                </p>
              </div>
              <XCircle className="h-8 w-8 text-red-600" />
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Filters */}
      <div className="mb-6 flex flex-col sm:flex-row gap-4">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-slate-400" />
          <Input
            placeholder="Search users..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="pl-10"
          />
        </div>
        <Select value={roleFilter} onValueChange={setRoleFilter}>
          <SelectTrigger className="w-full sm:w-48">
            <SelectValue placeholder="Filter by role" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="ALL">All Roles</SelectItem>
            <SelectItem value="SUPER_ADMIN">Super Admin</SelectItem>
            <SelectItem value="CUSTOMER">Customer</SelectItem>
            <SelectItem value="FUNDER">Funder</SelectItem>
            <SelectItem value="OM_PROVIDER">O&M Provider</SelectItem>
          </SelectContent>
        </Select>
        <Select value={statusFilter} onValueChange={setStatusFilter}>
          <SelectTrigger className="w-full sm:w-48">
            <SelectValue placeholder="Filter by status" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="ALL">All Status</SelectItem>
            <SelectItem value="ACTIVE">Active</SelectItem>
            <SelectItem value="INACTIVE">Inactive</SelectItem>
            <SelectItem value="UNVERIFIED">Unverified</SelectItem>
          </SelectContent>
        </Select>
      </div>

      {/* Users Table */}
      <Card>
        <CardHeader>
          <CardTitle>System Users</CardTitle>
          <CardDescription>Manage user accounts and access permissions</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-slate-200 dark:border-slate-700">
                  <th className="text-left py-3 px-4 font-medium text-slate-600 dark:text-slate-400">User</th>
                  <th className="text-left py-3 px-4 font-medium text-slate-600 dark:text-slate-400">Contact</th>
                  <th className="text-left py-3 px-4 font-medium text-slate-600 dark:text-slate-400">Roles</th>
                  <th className="text-left py-3 px-4 font-medium text-slate-600 dark:text-slate-400">Status</th>
                  <th className="text-left py-3 px-4 font-medium text-slate-600 dark:text-slate-400">Last Login</th>
                  <th className="text-right py-3 px-4 font-medium text-slate-600 dark:text-slate-400">Actions</th>
                </tr>
              </thead>
              <tbody>
                {filteredUsers.map((user) => (
                  <tr key={user.id} className="border-b border-slate-100 dark:border-slate-800 hover:bg-slate-50 dark:hover:bg-slate-800/50">
                    <td className="py-4 px-4">
                      <div className="flex items-center space-x-3">
                        <div className="w-10 h-10 bg-blue-500 rounded-full flex items-center justify-center">
                          <span className="text-white font-medium text-sm">
                            {user.firstName[0]}{user.lastName[0]}
                          </span>
                        </div>
                        <div>
                          <p className="font-medium text-slate-900 dark:text-slate-100">
                            {user.firstName} {user.lastName}
                          </p>
                          <p className="text-sm text-slate-500">{user.title}</p>
                          <p className="text-sm text-slate-500">{user.company}</p>
                        </div>
                      </div>
                    </td>
                    <td className="py-4 px-4">
                      <div className="space-y-1">
                        <div className="flex items-center text-sm text-slate-600 dark:text-slate-400">
                          <Mail className="h-3 w-3 mr-2" />
                          {user.email}
                        </div>
                        {user.phone && (
                          <div className="flex items-center text-sm text-slate-600 dark:text-slate-400">
                            <Phone className="h-3 w-3 mr-2" />
                            {user.phone}
                          </div>
                        )}
                      </div>
                    </td>
                    <td className="py-4 px-4">
                      <div className="flex flex-wrap gap-1">
                        {user.roles.map((role, index) => (
                          <Badge key={index} className={`${getRoleColor(role.roleName)} text-xs`}>
                            <div className="flex items-center space-x-1">
                              {getRoleIcon(role.roleName)}
                              <span>{role.roleName.replace('_', ' ')}</span>
                            </div>
                          </Badge>
                        ))}
                        {user.roles.length === 0 && (
                          <Badge variant="outline" className="text-xs">No roles assigned</Badge>
                        )}
                      </div>
                    </td>
                    <td className="py-4 px-4">
                      <div className="flex items-center space-x-2">
                        {user.isActive ? (
                          <Badge className="bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300">
                            Active
                          </Badge>
                        ) : (
                          <Badge className="bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300">
                            Inactive
                          </Badge>
                        )}
                        {!user.emailVerified && (
                          <Badge className="bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-300">
                            Unverified
                          </Badge>
                        )}
                      </div>
                    </td>
                    <td className="py-4 px-4">
                      <div className="text-sm text-slate-600 dark:text-slate-400">
                        {user.lastLogin ? (
                          <>
                            <div>{new Date(user.lastLogin).toLocaleDateString()}</div>
                            <div>{new Date(user.lastLogin).toLocaleTimeString()}</div>
                          </>
                        ) : (
                          'Never'
                        )}
                      </div>
                    </td>
                    <td className="py-4 px-4">
                      <div className="flex items-center justify-end space-x-2">
                        <DropdownMenu>
                          <DropdownMenuTrigger asChild>
                            <Button variant="ghost" size="sm">
                              <MoreHorizontal className="h-4 w-4" />
                            </Button>
                          </DropdownMenuTrigger>
                          <DropdownMenuContent align="end">
                            <DropdownMenuItem onClick={() => handleEditUser(user)}>
                              <Edit className="mr-2 h-4 w-4" />
                              Edit User
                            </DropdownMenuItem>
                            <DropdownMenuItem onClick={() => handleManageRoles(user)}>
                              <Shield className="mr-2 h-4 w-4" />
                              Manage Roles
                            </DropdownMenuItem>
                            <DropdownMenuItem onClick={() => handleSendPasswordReset(user.email)}>
                              <Key className="mr-2 h-4 w-4" />
                              Reset Password
                            </DropdownMenuItem>
                            <DropdownMenuItem onClick={() => handleToggleUserStatus(user.id)}>
                              {user.isActive ? (
                                <>
                                  <XCircle className="mr-2 h-4 w-4" />
                                  Deactivate
                                </>
                              ) : (
                                <>
                                  <CheckCircle className="mr-2 h-4 w-4" />
                                  Activate
                                </>
                              )}
                            </DropdownMenuItem>
                            <DropdownMenuItem 
                              className="text-red-600"
                              onClick={() => handleDeleteUser(user.id)}
                            >
                              <Trash2 className="mr-2 h-4 w-4" />
                              Delete User
                            </DropdownMenuItem>
                          </DropdownMenuContent>
                        </DropdownMenu>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {/* Empty State */}
          {filteredUsers.length === 0 && (
            <div className="text-center py-12">
              <Users className="mx-auto h-12 w-12 text-slate-400" />
              <h3 className="mt-2 text-sm font-medium text-slate-900 dark:text-slate-100">No users found</h3>
              <p className="mt-1 text-sm text-slate-500">
                {searchTerm || roleFilter !== 'ALL' || statusFilter !== 'ALL'
                  ? 'Try adjusting your search or filter criteria.'
                  : 'Get started by adding your first user.'
                }
              </p>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
};

export default UserManagement;