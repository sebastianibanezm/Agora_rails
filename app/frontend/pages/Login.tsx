import { useForm } from "@inertiajs/react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card"

interface Props {
  org_name?: string
  org_slug?: string
  flash?: { alert?: string }
}

export default function Login({ org_name, org_slug, flash }: Props) {
  const { data, setData, post, processing } = useForm({ email_address: "", password: "" })

  function submit(e: React.FormEvent) {
    e.preventDefault()
    post(org_slug ? `/${org_slug}/login` : "/admin/login")
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-slate-50">
      <Card className="w-full max-w-sm">
        <CardHeader>
          <CardTitle>Agora</CardTitle>
          <CardDescription>{org_name ? `Sign in to ${org_name}` : "Sign in"}</CardDescription>
        </CardHeader>
        <CardContent>
          {flash?.alert && <p className="text-sm text-red-600 mb-4">{flash.alert}</p>}
          <form onSubmit={submit} className="space-y-4">
            <div className="space-y-1">
              <Label htmlFor="email">Email</Label>
              <Input id="email" type="email" value={data.email_address} onChange={e => setData("email_address", e.target.value)} required />
            </div>
            <div className="space-y-1">
              <Label htmlFor="password">Password</Label>
              <Input id="password" type="password" value={data.password} onChange={e => setData("password", e.target.value)} required />
            </div>
            <Button type="submit" className="w-full" disabled={processing}>
              {processing ? "Signing in…" : "Sign in"}
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  )
}
