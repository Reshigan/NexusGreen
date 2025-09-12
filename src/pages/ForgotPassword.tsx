import { useState } from "react";
import { useNavigate, Link } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { useToast } from "@/hooks/use-toast";

const ForgotPassword = () => {
  const [email, setEmail] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const { toast } = useToast();
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email) return;
    try {
      setIsLoading(true);
      const res = await fetch('/api/auth/forgot-password', {
        method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email })
      });
      const raw = await res.text();
      let data: any = {}; try { data = JSON.parse(raw); } catch {}
      if (!res.ok || data.error) throw new Error(data?.error || `Failed: ${res.status}`);
      // If backend returns reset_link, navigate there; else show toast
      if (data.reset_link) {
        navigate(data.reset_link);
      } else {
        toast({ title: 'Reset Email Sent', description: 'Check your inbox for the reset link.' });
      }
    } catch (err: any) {
      toast({ title: 'Request Failed', description: err.message || 'Unexpected error', variant: 'destructive' });
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-primary to-primary-light p-4">
      <Card className="w-full max-w-md">
        <CardHeader className="text-center">
          <CardTitle className="text-2xl font-bold">Forgot Password</CardTitle>
          <CardDescription>Enter your email to receive a reset link</CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="email">Email</Label>
              <Input id="email" type="email" placeholder="you@example.com" value={email} onChange={(e) => setEmail(e.target.value)} required />
            </div>
            <Button type="submit" className="w-full" disabled={isLoading}>{isLoading ? 'Sending...' : 'Send Reset Link'}</Button>
          </form>
          <div className="mt-6 text-center text-sm text-muted-foreground">
            <p><Link to="/" className="underline">Back to Sign in</Link></p>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default ForgotPassword;


