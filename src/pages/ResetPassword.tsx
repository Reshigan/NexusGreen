import { useState } from "react";
import { useNavigate, useSearchParams, Link } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { useToast } from "@/hooks/use-toast";

const ResetPassword = () => {
  const [password, setPassword] = useState("");
  const [confirm, setConfirm] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [params] = useSearchParams();
  const token = params.get('token') || '';
  const { toast } = useToast();
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!password || !confirm || password !== confirm) {
      toast({ title: 'Reset Failed', description: 'Passwords must match', variant: 'destructive' });
      return;
    }
    try {
      setIsLoading(true);
      const res = await fetch('/api/auth/reset-password', {
        method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ token, newPassword: password })
      });
      const raw = await res.text();
      let data: any = {}; try { data = JSON.parse(raw); } catch {}
      if (!res.ok || data.error) throw new Error(data?.error || `Failed: ${res.status}`);
      toast({ title: 'Password Updated', description: 'You can now sign in.' });
      navigate('/');
    } catch (err: any) {
      toast({ title: 'Reset Failed', description: err.message || 'Unexpected error', variant: 'destructive' });
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-primary to-primary-light p-4">
      <Card className="w-full max-w-md">
        <CardHeader className="text-center">
          <CardTitle className="text-2xl font-bold">Reset Password</CardTitle>
          <CardDescription>Enter a new password to finish resetting</CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="password">New Password</Label>
              <Input id="password" type="password" placeholder="New password" value={password} onChange={(e) => setPassword(e.target.value)} required />
            </div>
            <div className="space-y-2">
              <Label htmlFor="confirm">Confirm New Password</Label>
              <Input id="confirm" type="password" placeholder="Repeat new password" value={confirm} onChange={(e) => setConfirm(e.target.value)} required />
            </div>
            <Button type="submit" className="w-full" disabled={isLoading}>{isLoading ? 'Updating...' : 'Update Password'}</Button>
          </form>
          <div className="mt-6 text-center text-sm text-muted-foreground">
            <p><Link to="/" className="underline">Back to Sign in</Link></p>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default ResetPassword;


