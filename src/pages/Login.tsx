import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { useToast } from "@/hooks/use-toast";
import { Link } from "react-router-dom";
import NexusGreenLogo from "@/components/NexusGreenLogo";
import { useAuth } from "@/contexts/AuthContext";

const Login = () => {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const navigate = useNavigate();
  const { toast } = useToast();
  const { login, user } = useAuth();

  // Redirect if already logged in
  useEffect(() => {
    if (user) {
      navigate('/dashboard');
    }
  }, [user, navigate]);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email || !password) {
      toast({ title: 'Login Failed', description: 'Please enter both email and password', variant: 'destructive' });
      return;
    }
    try {
      setIsLoading(true);
      await login(email, password);
      toast({ title: 'Login Successful', description: 'Welcome to Nexus Green Dashboard' });
      navigate('/dashboard');
    } catch (err: any) {
      toast({ title: 'Login Failed', description: err.message || 'Unexpected error', variant: 'destructive' });
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-slate-900 via-green-900 to-emerald-900 p-4 relative overflow-hidden">
      {/* Animated background elements */}
      <div className="absolute inset-0 overflow-hidden">
        <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-green-400/10 rounded-full blur-3xl animate-pulse"></div>
        <div className="absolute bottom-1/4 right-1/4 w-96 h-96 bg-emerald-400/10 rounded-full blur-3xl animate-pulse delay-1000"></div>
        <div className="absolute top-1/2 left-1/2 w-64 h-64 bg-teal-400/10 rounded-full blur-2xl animate-pulse delay-500"></div>
      </div>
      
      <Card className="w-full max-w-md relative z-10 border-0 bg-white/95 backdrop-blur-xl shadow-2xl">
        <CardHeader className="text-center pb-8">
          <div className="flex flex-col items-center gap-4">
            <NexusGreenLogo size="xl" variant="full" />
            <div>
              <CardTitle className="text-2xl font-bold bg-gradient-to-r from-green-600 via-emerald-600 to-teal-600 bg-clip-text text-transparent">
                Welcome Back
              </CardTitle>
              <CardDescription className="text-gray-600 font-medium mt-2">
                Next-Generation Solar Intelligence Platform
              </CardDescription>
            </div>
          </div>
        </CardHeader>
        <CardContent className="px-8 pb-8">
          <form onSubmit={handleLogin} className="space-y-6">
            <div className="space-y-2">
              <Label htmlFor="email" className="text-gray-700 font-semibold">Email Address</Label>
              <Input
                id="email"
                type="email"
                placeholder="admin@nexusgreen.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="h-12 border-2 border-gray-200 focus:border-green-500 focus:ring-green-500/20 transition-all duration-300"
                required
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="password" className="text-gray-700 font-semibold">Password</Label>
              <Input
                id="password"
                type="password"
                placeholder="Enter your password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="h-12 border-2 border-gray-200 focus:border-green-500 focus:ring-green-500/20 transition-all duration-300"
                required
              />
            </div>
            <Button
              type="submit"
              className="w-full h-12 bg-gradient-to-r from-green-500 via-emerald-500 to-teal-500 hover:from-green-600 hover:via-emerald-600 hover:to-teal-600 text-white font-semibold shadow-lg hover:shadow-xl transition-all duration-300 transform hover:scale-[1.02]"
              disabled={isLoading}
            >
              {isLoading ? (
                <div className="flex items-center gap-2">
                  <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
                  Signing In...
                </div>
              ) : (
                "Access Dashboard"
              )}
            </Button>
          </form>
          
          {/* Demo Credentials */}
          <div className="mt-6 p-4 bg-gradient-to-r from-green-50 to-emerald-50 rounded-lg border border-green-200">
            <h4 className="text-sm font-semibold text-green-800 mb-2">Demo Credentials</h4>
            <div className="text-xs text-green-700 space-y-1">
              <p><strong>Admin:</strong> admin@gonxt.tech / Demo2024!</p>
              <p><strong>User:</strong> user@gonxt.tech / Demo2024!</p>
            </div>
          </div>
          
          <div className="mt-6 text-center text-sm text-gray-500 space-y-2">
            <p>
              <Link to="/forgot-password" className="text-green-600 hover:text-green-700 font-medium transition-colors">Forgot your password?</Link>
            </p>
            <p>
              Need access? <Link to="/signup" className="text-green-600 hover:text-green-700 font-medium transition-colors">Request Account</Link>
            </p>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default Login;