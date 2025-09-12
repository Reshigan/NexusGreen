import { useState } from "react";
import { useNavigate, Link } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { useToast } from "@/hooks/use-toast";
import { Sun, Zap } from "lucide-react";

const Signup = () => {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirm, setConfirm] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const navigate = useNavigate();
  const { toast } = useToast();

  const handleSignup = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email || !password || !confirm) {
      toast({ title: "Sign Up Failed", description: "Please fill in all fields", variant: "destructive" });
      return;
    }
    if (password !== confirm) {
      toast({ title: "Passwords do not match", description: "Please confirm your password", variant: "destructive" });
      return;
    }
    try {
      setIsLoading(true);
      const res = await fetch('/api/auth/signup', {
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
      toast({ title: 'Account Created', description: 'You are now signed in.' });
      navigate('/dashboard');
    } catch (err: any) {
      toast({ title: 'Sign Up Failed', description: err.message || 'Unexpected error', variant: 'destructive' });
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-primary to-primary-light p-4">
      <Card className="w-full max-w-md">
        <CardHeader className="text-center">
          <div className="flex items-center justify-center mb-4">
            <div className="flex items-center space-x-2">
              <Sun className="h-8 w-8 text-accent" />
              <Zap className="h-6 w-6 text-warning" />
            </div>
          </div>
          <CardTitle className="text-2xl font-bold">Create Account</CardTitle>
          <CardDescription>Sign up to access your Solar Investment Dashboard</CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSignup} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="email">Email</Label>
              <Input id="email" type="email" placeholder="you@example.com" value={email} onChange={(e) => setEmail(e.target.value)} required />
            </div>
            <div className="space-y-2">
              <Label htmlFor="password">Password</Label>
              <Input id="password" type="password" placeholder="Create a password" value={password} onChange={(e) => setPassword(e.target.value)} required />
            </div>
            <div className="space-y-2">
              <Label htmlFor="confirm">Confirm Password</Label>
              <Input id="confirm" type="password" placeholder="Repeat your password" value={confirm} onChange={(e) => setConfirm(e.target.value)} required />
            </div>
            <Button type="submit" className="w-full" disabled={isLoading}>
              {isLoading ? "Creating Account..." : "Sign Up"}
            </Button>
          </form>
          <div className="mt-6 text-center text-sm text-muted-foreground">
            <p>
              Already have an account? {""}
              <Link to="/" className="underline">Sign in</Link>
            </p>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default Signup;


