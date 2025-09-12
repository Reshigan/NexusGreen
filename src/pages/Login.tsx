import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { useToast } from "@/hooks/use-toast";
 
import { Link } from "react-router-dom";

const API_URL = import.meta.env.VITE_API_URL || "";

const Login = () => {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const navigate = useNavigate();
  const { toast } = useToast();

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email || !password) {
      toast({ title: 'Login Failed', description: 'Please enter both email and password', variant: 'destructive' });
      return;
    }
    try {
      setIsLoading(true);
      const res = await fetch(`${API_URL}/api/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include',
        body: JSON.stringify({ email, password }),
      });
      const ct = res.headers.get('content-type') || '';
      const raw = await res.text();
      let data: any = {};
      if (ct.includes('application/json') && raw) { try { data = JSON.parse(raw); } catch {} }
      if (!res.ok || data.error) { throw new Error(data?.error || `Failed with status ${res.status}`); }
      toast({ title: 'Login Successful', description: 'Welcome to your Solar Investment Dashboard' });
      navigate('/dashboard');
    } catch (err: any) {
      toast({ title: 'Login Failed', description: err.message || 'Unexpected error', variant: 'destructive' });
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-primary to-primary-light p-4">
      <Card className="w-full max-w-md">
        <CardHeader className="text-center">
          <div className="flex flex-col items-center gap-2">
            <img
              src="/gonxt-logo.jpeg"
              alt="GoNXT logo"
              title="GoNXT"
              className="h-14 md:h-16 w-auto object-contain drop-shadow-sm"
              loading="eager"
              decoding="async"
            />
            <CardTitle className="text-2xl font-bold">PPA Dashboard</CardTitle>
          </div>
          <CardDescription>
            Welcome to your Solar Investment Dashboard
          </CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleLogin} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="email">Email</Label>
              <Input
                id="email"
                type="email"
                placeholder="investor@solarfund.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="password">Password</Label>
              <Input
                id="password"
                type="password"
                placeholder="Enter your password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
              />
            </div>
            <Button
              type="submit"
              className="w-full"
              disabled={isLoading}
            >
              {isLoading ? "Signing In..." : "Sign In"}
            </Button>
          </form>
          <div className="hidden mt-6 text-center text-sm text-muted-foreground space-y-2">
            <p>
              <Link to="/forgot-password" className="underline">Forgot your password?</Link>
            </p>
            <p>
              Don't have an account? <Link to="/signup" className="underline">Sign up</Link>
            </p>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default Login;