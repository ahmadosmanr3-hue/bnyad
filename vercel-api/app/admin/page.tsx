'use client';

import { useCallback, useEffect, useState } from 'react';

/* ------------------------------------------------------------------ */
/* Types                                                               */
/* ------------------------------------------------------------------ */

type Split = { name: string; share: number; amount: number };

type Stats = {
  totalUsers: number;
  totalSubscriptions: number;
  activeSubscriptions: number;
  totalRevenue: number;
  monthRevenue: number;
  split: { total: Split[]; month: Split[] };
};

type AdminUser = {
  id: number;
  name: string;
  phone: string | null;
  email: string;
  language: string | null;
  goal: string | null;
  onboarded: boolean;
  phoneVerified: boolean;
  createdAt: string;
  isPremium: boolean;
  plan: string | null;
  daysLeft: number;
  expiresAt: string | null;
  subscriptionCount: number;
  totalPaid: number;
};

type AdminSub = {
  id: number;
  userId: number;
  userName: string;
  phone: string | null;
  plan: string;
  amount: number;
  currency: string;
  startedAt: string;
  expiresAt: string;
  note: string | null;
  active: boolean;
  daysLeft: number;
  createdAt: string;
};

type AdminNote = {
  id: number;
  title: string;
  body: string;
  target: string;
  userId: number | null;
  createdAt: string;
};

/* ------------------------------------------------------------------ */
/* Theme                                                               */
/* ------------------------------------------------------------------ */

const C = {
  bg: '#0b0f19',
  panel: '#141a2a',
  panel2: '#1b2336',
  border: '#26304a',
  text: '#e8edf7',
  muted: '#93a0bd',
  indigo: '#6366f1',
  violet: '#8b5cf6',
  green: '#22c55e',
  red: '#ef4444',
  amber: '#f59e0b',
};

const TABS = ['Dashboard', 'Users', 'Subscriptions', 'Notifications'] as const;
type Tab = (typeof TABS)[number];

/* ------------------------------------------------------------------ */
/* Page                                                                */
/* ------------------------------------------------------------------ */

export default function AdminPage() {
  const [secret, setSecret] = useState<string | null>(null);
  const [tab, setTab] = useState<Tab>('Dashboard');

  useEffect(() => {
    setSecret(localStorage.getItem('bnyad_admin_secret'));
  }, []);

  const logout = () => {
    localStorage.removeItem('bnyad_admin_secret');
    setSecret(null);
  };

  if (secret === null) {
    return <Login onLogin={(s) => setSecret(s)} />;
  }

  return (
    <div style={{ minHeight: '100vh', background: C.bg, color: C.text, fontFamily: 'system-ui, -apple-system, sans-serif' }}>
      <header
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          padding: '16px 22px',
          borderBottom: `1px solid ${C.border}`,
          position: 'sticky',
          top: 0,
          background: C.bg,
          zIndex: 10,
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <div
            style={{
              width: 34,
              height: 34,
              borderRadius: 10,
              background: `linear-gradient(135deg, ${C.indigo}, ${C.violet})`,
              display: 'grid',
              placeItems: 'center',
              fontWeight: 900,
            }}
          >
            B
          </div>
          <strong style={{ fontSize: 17, letterSpacing: -0.3 }}>BNYAD Admin</strong>
        </div>
        <button onClick={logout} style={btn(C.panel2, C.text)}>
          Log out
        </button>
      </header>

      <nav style={{ display: 'flex', gap: 6, padding: '14px 22px 0', flexWrap: 'wrap' }}>
        {TABS.map((t) => (
          <button
            key={t}
            onClick={() => setTab(t)}
            style={{
              ...btn(tab === t ? C.indigo : C.panel, tab === t ? '#fff' : C.muted),
              fontWeight: tab === t ? 800 : 600,
            }}
          >
            {t}
          </button>
        ))}
      </nav>

      <main style={{ padding: 22, maxWidth: 1100, margin: '0 auto' }}>
        {tab === 'Dashboard' && <Dashboard secret={secret} />}
        {tab === 'Users' && <Users secret={secret} />}
        {tab === 'Subscriptions' && <Subscriptions secret={secret} />}
        {tab === 'Notifications' && <Notifications secret={secret} />}
      </main>
    </div>
  );
}

/* ------------------------------------------------------------------ */
/* Login                                                               */
/* ------------------------------------------------------------------ */

function Login({ onLogin }: { onLogin: (secret: string) => void }) {
  const [value, setValue] = useState('');
  const [err, setErr] = useState('');
  const [loading, setLoading] = useState(false);

  const submit = async () => {
    setErr('');
    setLoading(true);
    try {
      const res = await fetch('/api/admin/login', {
        method: 'POST',
        headers: { 'x-admin-secret': value },
      });
      if (!res.ok) {
        const j = await res.json().catch(() => ({}));
        setErr(j.message || 'Login failed.');
        return;
      }
      localStorage.setItem('bnyad_admin_secret', value);
      onLogin(value);
    } catch {
      setErr('Network error.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div
      style={{
        minHeight: '100vh',
        background: C.bg,
        color: C.text,
        display: 'grid',
        placeItems: 'center',
        fontFamily: 'system-ui, sans-serif',
        padding: 20,
      }}
    >
      <div style={{ ...card(), width: 360, maxWidth: '100%' }}>
        <div
          style={{
            width: 48,
            height: 48,
            borderRadius: 14,
            margin: '0 auto 16px',
            background: `linear-gradient(135deg, ${C.indigo}, ${C.violet})`,
            display: 'grid',
            placeItems: 'center',
            fontWeight: 900,
            fontSize: 22,
          }}
        >
          B
        </div>
        <h1 style={{ textAlign: 'center', fontSize: 20, margin: '0 0 4px' }}>BNYAD Admin</h1>
        <p style={{ textAlign: 'center', color: C.muted, fontSize: 13, margin: '0 0 20px' }}>
          Enter the admin password
        </p>
        <input
          type="password"
          value={value}
          autoFocus
          placeholder="Admin password"
          onChange={(e) => setValue(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && submit()}
          style={input()}
        />
        {err && <div style={{ color: C.red, fontSize: 13, marginTop: 10 }}>{err}</div>}
        <button onClick={submit} disabled={loading || !value} style={{ ...btn(C.indigo, '#fff'), width: '100%', marginTop: 16, padding: 12 }}>
          {loading ? '…' : 'Enter'}
        </button>
      </div>
    </div>
  );
}

/* ------------------------------------------------------------------ */
/* Data hook                                                           */
/* ------------------------------------------------------------------ */

function useApi(secret: string) {
  return useCallback(
    async (path: string, init?: RequestInit) => {
      const res = await fetch(path, {
        ...init,
        headers: { 'x-admin-secret': secret, 'Content-Type': 'application/json', ...(init?.headers ?? {}) },
      });
      const j = await res.json().catch(() => ({}));
      if (!res.ok) throw new Error(j.message || `Error ${res.status}`);
      return j;
    },
    [secret],
  );
}

/* ------------------------------------------------------------------ */
/* Dashboard                                                           */
/* ------------------------------------------------------------------ */

function Dashboard({ secret }: { secret: string }) {
  const api = useApi(secret);
  const [stats, setStats] = useState<Stats | null>(null);
  const [err, setErr] = useState('');

  useEffect(() => {
    api('/api/admin/stats')
      .then(setStats)
      .catch((e) => setErr(e.message));
  }, [api]);

  if (err) return <ErrorBox msg={err} />;
  if (!stats) return <Loading />;

  return (
    <div style={{ display: 'grid', gap: 18 }}>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(160px, 1fr))', gap: 14 }}>
        <Stat label="Total users" value={stats.totalUsers} />
        <Stat label="Active premium" value={stats.activeSubscriptions} accent={C.green} />
        <Stat label="Total sales" value={stats.totalSubscriptions} />
        <Stat label="Total revenue" value={money(stats.totalRevenue)} accent={C.amber} />
        <Stat label="This month" value={money(stats.monthRevenue)} accent={C.violet} />
      </div>

      <RevenueSplit stats={stats} />
    </div>
  );
}

const OWNER_COLORS = [C.indigo, C.amber, C.green, C.violet];

function RevenueSplit({ stats }: { stats: Stats }) {
  const owners = stats.split.total.map((s, i) => {
    const monthMatch = stats.split.month.find((m) => m.name === s.name);
    return {
      name: s.name,
      share: s.share,
      color: OWNER_COLORS[i % OWNER_COLORS.length],
      allTime: s.amount,
      month: monthMatch?.amount ?? 0,
    };
  });

  return (
    <div style={card(20)}>
      <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', flexWrap: 'wrap', gap: 8, marginBottom: 16 }}>
        <div>
          <h3 style={{ margin: 0, fontSize: 16 }}>Revenue split</h3>
          <div style={{ fontSize: 12.5, color: C.muted, marginTop: 3 }}>
            How total earnings are divided between the owners
          </div>
        </div>
        <div style={{ textAlign: 'right' }}>
          <div style={{ fontSize: 11, color: C.muted, textTransform: 'uppercase', letterSpacing: 0.5 }}>Total revenue</div>
          <div style={{ fontSize: 20, fontWeight: 900 }}>{money(stats.totalRevenue)}</div>
        </div>
      </div>

      {/* Single proportion bar */}
      <div style={{ display: 'flex', height: 16, borderRadius: 8, overflow: 'hidden', marginBottom: 10 }}>
        {owners.map((o) => (
          <div
            key={o.name}
            title={`${o.name} — ${Math.round(o.share * 100)}%`}
            style={{ width: `${o.share * 100}%`, background: o.color, minWidth: 2 }}
          />
        ))}
      </div>
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 16, marginBottom: 20 }}>
        {owners.map((o) => (
          <div key={o.name} style={{ display: 'flex', alignItems: 'center', gap: 7, fontSize: 13 }}>
            <span style={{ width: 11, height: 11, borderRadius: 3, background: o.color, display: 'inline-block' }} />
            <span style={{ fontWeight: 700 }}>{o.name}</span>
            <span style={{ color: C.muted }}>{Math.round(o.share * 100)}%</span>
          </div>
        ))}
      </div>

      {/* Per-owner detail cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: 14 }}>
        {owners.map((o) => (
          <div
            key={o.name}
            style={{
              background: C.panel2,
              border: `1px solid ${C.border}`,
              borderRadius: 14,
              padding: 16,
              borderTop: `3px solid ${o.color}`,
            }}
          >
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
              <span style={{ fontWeight: 800, fontSize: 15 }}>{o.name}</span>
              <span
                style={{
                  fontSize: 12,
                  fontWeight: 800,
                  color: o.color,
                  background: `${o.color}22`,
                  padding: '3px 9px',
                  borderRadius: 999,
                }}
              >
                {Math.round(o.share * 100)}%
              </span>
            </div>
            <div style={{ marginBottom: 12 }}>
              <div style={{ fontSize: 11, color: C.muted, textTransform: 'uppercase', letterSpacing: 0.5, marginBottom: 3 }}>
                All-time earnings
              </div>
              <div style={{ fontSize: 24, fontWeight: 900 }}>{money(o.allTime)}</div>
            </div>
            <div style={{ borderTop: `1px solid ${C.border}`, paddingTop: 10, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span style={{ fontSize: 12.5, color: C.muted }}>This month</span>
              <strong style={{ fontSize: 15, color: C.green }}>{money(o.month)}</strong>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

function Stat({ label, value, accent }: { label: string; value: string | number; accent?: string }) {
  return (
    <div style={card()}>
      <div style={{ fontSize: 12, color: C.muted, marginBottom: 8, textTransform: 'uppercase', letterSpacing: 0.5 }}>{label}</div>
      <div style={{ fontSize: 26, fontWeight: 900, color: accent ?? C.text }}>{value}</div>
    </div>
  );
}

/* ------------------------------------------------------------------ */
/* Users                                                               */
/* ------------------------------------------------------------------ */

function Users({ secret }: { secret: string }) {
  const api = useApi(secret);
  const [users, setUsers] = useState<AdminUser[]>([]);
  const [q, setQ] = useState('');
  const [err, setErr] = useState('');
  const [loading, setLoading] = useState(true);
  const [selectedId, setSelectedId] = useState<number | null>(null);
  const [showAddModal, setShowAddModal] = useState(false);

  const load = useCallback(
    (search = '') => {
      setLoading(true);
      api(`/api/admin/users${search ? `?q=${encodeURIComponent(search)}` : ''}`)
        .then((j) => setUsers(j.data))
        .catch((e) => setErr(e.message))
        .finally(() => setLoading(false));
    },
    [api],
  );

  useEffect(() => {
    load();
  }, [load]);

  if (err) return <ErrorBox msg={err} />;

  return (
    <div style={{ display: 'grid', gap: 14 }}>
      <div style={{ display: 'flex', gap: 8 }}>
        <input
          value={q}
          placeholder="Search by name, phone or email"
          onChange={(e) => setQ(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && load(q)}
          style={{ ...input(), flex: 1 }}
        />
        <button onClick={() => load(q)} style={btn(C.indigo, '#fff')}>
          Search
        </button>
        <button onClick={() => setShowAddModal(true)} style={btn(C.green, '#fff')}>
          Add User
        </button>
      </div>

      {loading ? (
        <Loading />
      ) : (
        <div style={card(0)}>
          <Table
            head={['#', 'Name', 'Phone', 'Status', 'Plan', 'Days left', 'Paid', 'Joined', '']}
            rows={users.map((u) => [
              u.id,
              <span key="n">
                {u.name}
                {!u.onboarded && <Tag color={C.muted}>new</Tag>}
              </span>,
              u.phone ?? '—',
              u.isPremium ? <Tag color={C.green}>Premium</Tag> : <Tag color={C.muted}>Free</Tag>,
              u.isPremium ? <Tag color={C.violet}>{u.plan || 'custom'}</Tag> : '—',
              u.isPremium ? `${u.daysLeft}d` : '—',
              money(u.totalPaid),
              fmtDate(u.createdAt),
              <button key="m" onClick={() => setSelectedId(u.id)} style={btn(C.panel2, C.indigo, true)}>
                Manage
              </button>,
            ])}
          />
          {users.length === 0 && <Empty msg="No users found." />}
        </div>
      )}

      {selectedId !== null && (
        <UserModal
          secret={secret}
          userId={selectedId}
          onClose={() => setSelectedId(null)}
          onChanged={() => load(q)}
        />
      )}

      {showAddModal && (
        <AddUserModal
          secret={secret}
          onClose={() => setShowAddModal(false)}
          onChanged={() => load(q)}
        />
      )}
    </div>
  );
}

/* ------------------------------------------------------------------ */
/* Add User Modal                                                     */
/* ------------------------------------------------------------------ */

function AddUserModal({
  secret,
  onClose,
  onChanged,
}: {
  secret: string;
  onClose: () => void;
  onChanged: () => void;
}) {
  const api = useApi(secret);
  const [name, setName] = useState('');
  const [phone, setPhone] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [phoneVerified, setPhoneVerified] = useState(false);
  const [err, setErr] = useState('');
  const [busy, setBusy] = useState(false);

  const save = async () => {
    setErr('');
    setBusy(true);
    try {
      await api('/api/admin/users', {
        method: 'POST',
        body: JSON.stringify({
          name: name.trim(),
          phone: phone.trim() || undefined,
          email: email.trim() || undefined,
          password: password,
          phoneVerified,
        }),
      });
      onChanged();
      onClose();
    } catch (e) {
      setErr((e as Error).message);
    } finally {
      setBusy(false);
    }
  };

  return (
    <div
      onClick={onClose}
      style={{
        position: 'fixed',
        inset: 0,
        background: 'rgba(0,0,0,0.6)',
        display: 'grid',
        placeItems: 'center',
        zIndex: 50,
        padding: 16,
      }}
    >
      <div
        onClick={(e) => e.stopPropagation()}
        style={{ ...card(), width: 420, maxWidth: '100%', maxHeight: '90vh', overflowY: 'auto' }}
      >
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
          <h3 style={{ margin: 0, fontSize: 16 }}>Add new user</h3>
          <button onClick={onClose} style={btn(C.panel2, C.muted, true)}>
            Close
          </button>
        </div>

        <Field label="Name">
          <input value={name} onChange={(e) => setName(e.target.value)} placeholder="Full name" style={input()} />
        </Field>
        <Field label="Phone (optional)">
          <input value={phone} onChange={(e) => setPhone(e.target.value)} placeholder="+9647..." style={input()} />
        </Field>
        <Field label="Email (optional)">
          <input value={email} onChange={(e) => setEmail(e.target.value)} placeholder="user@example.com" style={input()} />
        </Field>
        <Field label="Password">
          <input type="password" value={password} onChange={(e) => setPassword(e.target.value)} placeholder="At least 6 characters" style={input()} />
        </Field>

        <label style={{ display: 'flex', alignItems: 'center', gap: 8, margin: '14px 0', cursor: 'pointer' }}>
          <input type="checkbox" checked={phoneVerified} onChange={(e) => setPhoneVerified(e.target.checked)} />
          <span style={{ fontSize: 13.5 }}>Phone Verified</span>
        </label>

        {err && <div style={{ color: C.red, fontSize: 13, marginTop: 12 }}>{err}</div>}

        <button onClick={save} disabled={busy || !name || !password} style={{ ...btn(C.indigo, '#fff'), width: '100%', marginTop: 16, padding: 12 }}>
          {busy ? 'Creating…' : 'Create user'}
        </button>
      </div>
    </div>
  );
}

/* ------------------------------------------------------------------ */
/* User detail / edit modal                                            */
/* ------------------------------------------------------------------ */

type UserDetail = {
  id: number;
  name: string;
  phone: string | null;
  email: string;
  phoneVerified: boolean;
  createdAt: string;
  isPremium: boolean;
  plan: string | null;
  daysLeft: number;
  expiresAt: string | null;
  profile: Record<string, unknown> | null;
};

function UserModal({
  secret,
  userId,
  onClose,
  onChanged,
}: {
  secret: string;
  userId: number;
  onClose: () => void;
  onChanged: () => void;
}) {
  const api = useApi(secret);
  const [user, setUser] = useState<UserDetail | null>(null);
  const [err, setErr] = useState('');
  const [msg, setMsg] = useState('');
  const [busy, setBusy] = useState(false);

  // Editable fields.
  const [name, setName] = useState('');
  const [phone, setPhone] = useState('');
  const [displayName, setDisplayName] = useState('');
  const [calories, setCalories] = useState('');
  const [protein, setProtein] = useState('');
  const [carbs, setCarbs] = useState('');
  const [fat, setFat] = useState('');
  const [password, setPassword] = useState('');

  const load = useCallback(() => {
    api(`/api/admin/users/${userId}`)
      .then((j) => {
        const u = j.data as UserDetail;
        setUser(u);
        setName(u.name ?? '');
        setPhone(u.phone ?? '');
        const p = u.profile ?? {};
        setDisplayName((p.display_name as string) ?? '');
        setCalories(String((p.daily_calories as number) ?? ''));
        setProtein(String((p.daily_protein as number) ?? ''));
        setCarbs(String((p.daily_carbs as number) ?? ''));
        setFat(String((p.daily_fat as number) ?? ''));
      })
      .catch((e) => setErr(e.message));
  }, [api, userId]);

  useEffect(() => {
    load();
  }, [load]);

  const save = async () => {
    setErr('');
    setMsg('');
    setBusy(true);
    try {
      await api(`/api/admin/users/${userId}`, {
        method: 'PATCH',
        body: JSON.stringify({
          name: name.trim(),
          phone: phone.trim(),
          display_name: displayName.trim(),
          daily_calories: Number(calories) || 0,
          daily_protein: Number(protein) || 0,
          daily_carbs: Number(carbs) || 0,
          daily_fat: Number(fat) || 0,
          password: password.trim() || undefined,
        }),
      });
      setMsg('Saved.');
      setPassword('');
      onChanged();
    } catch (e) {
      setErr((e as Error).message);
    } finally {
      setBusy(false);
    }
  };

  const reset = async () => {
    if (!confirm('Reset this user\'s data? This deletes all food logs, water, weight history and meal plan, and makes them redo onboarding. Login and subscription are kept.')) return;
    setErr('');
    setMsg('');
    setBusy(true);
    try {
      await api(`/api/admin/users/${userId}/reset`, { method: 'POST' });
      setMsg('User data reset. They will redo onboarding on next app open.');
      onChanged();
      load();
    } catch (e) {
      setErr((e as Error).message);
    } finally {
      setBusy(false);
    }
  };

  const remove = async () => {
    if (!confirm('Permanently DELETE this user and all their data? This cannot be undone.')) return;
    setBusy(true);
    try {
      await api(`/api/admin/users/${userId}`, { method: 'DELETE' });
      onChanged();
      onClose();
    } catch (e) {
      setErr((e as Error).message);
      setBusy(false);
    }
  };

  return (
    <div
      onClick={onClose}
      style={{
        position: 'fixed',
        inset: 0,
        background: 'rgba(0,0,0,0.6)',
        display: 'grid',
        placeItems: 'center',
        zIndex: 50,
        padding: 16,
      }}
    >
      <div
        onClick={(e) => e.stopPropagation()}
        style={{ ...card(), width: 460, maxWidth: '100%', maxHeight: '90vh', overflowY: 'auto' }}
      >
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
          <h3 style={{ margin: 0, fontSize: 16 }}>Manage user #{userId}</h3>
          <button onClick={onClose} style={btn(C.panel2, C.muted, true)}>
            Close
          </button>
        </div>

        {!user ? (
          <Loading />
        ) : (
          <>
            <div style={{ fontSize: 12, color: C.muted, marginBottom: 16 }}>
              Joined {fmtDate(user.createdAt)} · {user.isPremium ? `${user.plan || 'Premium'} (${user.daysLeft}d left, expires ${fmtDate(user.expiresAt!)})` : 'Free'}
            </div>

            <Field label="Login name">
              <input value={name} onChange={(e) => setName(e.target.value)} style={input()} />
            </Field>
            <Field label="Phone (login)">
              <input value={phone} onChange={(e) => setPhone(e.target.value)} style={input()} />
            </Field>
            <Field label="Display name">
              <input value={displayName} onChange={(e) => setDisplayName(e.target.value)} style={input()} />
            </Field>
            <Field label="Password (leave blank to keep unchanged)">
              <input type="password" value={password} placeholder="••••••" onChange={(e) => setPassword(e.target.value)} style={input()} />
            </Field>

            <div style={{ fontSize: 12, color: C.muted, margin: '14px 0 8px', textTransform: 'uppercase', letterSpacing: 0.5 }}>
              Daily macros
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
              <Field label="Calories">
                <input value={calories} type="number" onChange={(e) => setCalories(e.target.value)} style={input()} />
              </Field>
              <Field label="Protein (g)">
                <input value={protein} type="number" onChange={(e) => setProtein(e.target.value)} style={input()} />
              </Field>
              <Field label="Carbs (g)">
                <input value={carbs} type="number" onChange={(e) => setCarbs(e.target.value)} style={input()} />
              </Field>
              <Field label="Fat (g)">
                <input value={fat} type="number" onChange={(e) => setFat(e.target.value)} style={input()} />
              </Field>
            </div>

            {err && <div style={{ color: C.red, fontSize: 13, marginTop: 12 }}>{err}</div>}
            {msg && <div style={{ color: C.green, fontSize: 13, marginTop: 12 }}>{msg}</div>}

            <button onClick={save} disabled={busy} style={{ ...btn(C.indigo, '#fff'), width: '100%', marginTop: 16, padding: 12 }}>
              {busy ? 'Working…' : 'Save changes'}
            </button>

            <div style={{ borderTop: `1px solid ${C.border}`, marginTop: 18, paddingTop: 16, display: 'grid', gap: 10 }}>
              <div style={{ fontSize: 12, color: C.muted }}>Danger zone</div>
              <button onClick={reset} disabled={busy} style={{ ...btn('#3a2a12', C.amber), width: '100%', padding: 11 }}>
                Reset data (redo onboarding)
              </button>
              <button onClick={remove} disabled={busy} style={{ ...btn('#3a1620', C.red), width: '100%', padding: 11 }}>
                Delete user permanently
              </button>
            </div>
          </>
        )}
      </div>
    </div>
  );
}

/* ------------------------------------------------------------------ */
/* Subscriptions                                                       */
/* ------------------------------------------------------------------ */

function Subscriptions({ secret }: { secret: string }) {
  const api = useApi(secret);
  const [subs, setSubs] = useState<AdminSub[]>([]);
  const [err, setErr] = useState('');
  const [msg, setMsg] = useState('');
  const [loading, setLoading] = useState(true);

  const [phone, setPhone] = useState('');
  const [days, setDays] = useState('30');
  const [amount, setAmount] = useState('');
  const [currency, setCurrency] = useState('USD');
  const [plan, setPlan] = useState('monthly');
  const [note, setNote] = useState('');
  const [saving, setSaving] = useState(false);

  const load = useCallback(() => {
    setLoading(true);
    api('/api/admin/subscriptions')
      .then((j) => setSubs(j.data))
      .catch((e) => setErr(e.message))
      .finally(() => setLoading(false));
  }, [api]);

  useEffect(() => {
    load();
  }, [load]);

  const grant = async () => {
    setErr('');
    setMsg('');
    setSaving(true);
    try {
      await api('/api/admin/subscriptions', {
        method: 'POST',
        body: JSON.stringify({
          phone: phone.trim(),
          days: Number(days),
          amount: Number(amount || 0),
          currency,
          plan,
          note: note.trim() || undefined,
        }),
      });
      setMsg('Subscription recorded.');
      setPhone('');
      setAmount('');
      setNote('');
      load();
    } catch (e) {
      setErr((e as Error).message);
    } finally {
      setSaving(false);
    }
  };

  const cancel = async (id: number) => {
    if (!confirm('Cancel this subscription?')) return;
    try {
      await api(`/api/admin/subscriptions/${id}`, { method: 'DELETE' });
      load();
    } catch (e) {
      setErr((e as Error).message);
    }
  };

  return (
    <div style={{ display: 'grid', gap: 16 }}>
      <div style={card()}>
        <h3 style={{ margin: '0 0 14px', fontSize: 15 }}>Record a sale / give premium</h3>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(150px, 1fr))', gap: 10 }}>
          <Field label="User phone">
            <input value={phone} onChange={(e) => setPhone(e.target.value)} placeholder="+9647..." style={input()} />
          </Field>
          <Field label="Days">
            <input value={days} onChange={(e) => setDays(e.target.value)} type="number" style={input()} />
          </Field>
          <Field label="Amount paid">
            <input value={amount} onChange={(e) => setAmount(e.target.value)} type="number" placeholder="0" style={input()} />
          </Field>
          <Field label="Currency">
            <input value={currency} onChange={(e) => setCurrency(e.target.value)} style={input()} />
          </Field>
          <Field label="Plan">
            <input value={plan} onChange={(e) => setPlan(e.target.value)} placeholder="monthly" style={input()} />
          </Field>
          <Field label="Note (optional)">
            <input value={note} onChange={(e) => setNote(e.target.value)} style={input()} />
          </Field>
        </div>
        {err && <div style={{ color: C.red, fontSize: 13, marginTop: 12 }}>{err}</div>}
        {msg && <div style={{ color: C.green, fontSize: 13, marginTop: 12 }}>{msg}</div>}
        <button onClick={grant} disabled={saving || !phone || !days} style={{ ...btn(C.indigo, '#fff'), marginTop: 14 }}>
          {saving ? 'Saving…' : 'Add subscription'}
        </button>
      </div>

      {loading ? (
        <Loading />
      ) : (
        <div style={card(0)}>
          <Table
            head={['#', 'User', 'Phone', 'Plan', 'Amount', 'Days left', 'Expires', 'Status', '']}
            rows={subs.map((s) => [
              s.id,
              s.userName,
              s.phone ?? '—',
              s.plan,
              `${money(s.amount)} ${s.currency}`,
              s.active ? `${s.daysLeft}d` : '—',
              fmtDate(s.expiresAt),
              s.active ? <Tag color={C.green}>Active</Tag> : <Tag color={C.muted}>Ended</Tag>,
              s.active ? (
                <button key="x" onClick={() => cancel(s.id)} style={btn(C.panel2, C.red, true)}>
                  Cancel
                </button>
              ) : (
                ''
              ),
            ])}
          />
          {subs.length === 0 && <Empty msg="No subscriptions yet." />}
        </div>
      )}
    </div>
  );
}

/* ------------------------------------------------------------------ */
/* Notifications                                                       */
/* ------------------------------------------------------------------ */

function Notifications({ secret }: { secret: string }) {
  const api = useApi(secret);
  const [notes, setNotes] = useState<AdminNote[]>([]);
  const [err, setErr] = useState('');
  const [msg, setMsg] = useState('');
  const [loading, setLoading] = useState(true);

  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [phone, setPhone] = useState('');
  const [broadcast, setBroadcast] = useState(true);
  const [sending, setSending] = useState(false);

  const load = useCallback(() => {
    setLoading(true);
    api('/api/admin/notifications')
      .then((j) => setNotes(j.data))
      .catch((e) => setErr(e.message))
      .finally(() => setLoading(false));
  }, [api]);

  useEffect(() => {
    load();
  }, [load]);

  const send = async () => {
    setErr('');
    setMsg('');
    setSending(true);
    try {
      await api('/api/admin/notifications', {
        method: 'POST',
        body: JSON.stringify({
          title: title.trim(),
          body: body.trim(),
          phone: broadcast ? undefined : phone.trim(),
        }),
      });
      setMsg('Notification sent.');
      setTitle('');
      setBody('');
      setPhone('');
      load();
    } catch (e) {
      setErr((e as Error).message);
    } finally {
      setSending(false);
    }
  };

  return (
    <div style={{ display: 'grid', gap: 16 }}>
      <div style={card()}>
        <h3 style={{ margin: '0 0 14px', fontSize: 15 }}>Send a notification</h3>
        <div style={{ display: 'flex', gap: 14, marginBottom: 12, flexWrap: 'wrap' }}>
          <label style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 14, cursor: 'pointer' }}>
            <input type="radio" checked={broadcast} onChange={() => setBroadcast(true)} /> All users
          </label>
          <label style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 14, cursor: 'pointer' }}>
            <input type="radio" checked={!broadcast} onChange={() => setBroadcast(false)} /> One user (by phone)
          </label>
        </div>
        {!broadcast && (
          <Field label="User phone">
            <input value={phone} onChange={(e) => setPhone(e.target.value)} placeholder="+9647..." style={input()} />
          </Field>
        )}
        <Field label="Title">
          <input value={title} onChange={(e) => setTitle(e.target.value)} style={input()} />
        </Field>
        <Field label="Message">
          <textarea value={body} onChange={(e) => setBody(e.target.value)} rows={3} style={{ ...input(), resize: 'vertical' }} />
        </Field>
        {err && <div style={{ color: C.red, fontSize: 13, marginTop: 10 }}>{err}</div>}
        {msg && <div style={{ color: C.green, fontSize: 13, marginTop: 10 }}>{msg}</div>}
        <button onClick={send} disabled={sending || !title || !body || (!broadcast && !phone)} style={{ ...btn(C.indigo, '#fff'), marginTop: 14 }}>
          {sending ? 'Sending…' : 'Send notification'}
        </button>
      </div>

      {loading ? (
        <Loading />
      ) : (
        <div style={card(0)}>
          <Table
            head={['#', 'Title', 'Message', 'To', 'Sent']}
            rows={notes.map((n) => [n.id, n.title, n.body, <Tag key="t" color={n.userId ? C.indigo : C.violet}>{n.target}</Tag>, fmtDate(n.createdAt)])}
          />
          {notes.length === 0 && <Empty msg="No notifications sent yet." />}
        </div>
      )}
    </div>
  );
}

/* ------------------------------------------------------------------ */
/* Shared bits                                                         */
/* ------------------------------------------------------------------ */

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <label style={{ display: 'block', marginBottom: 10 }}>
      <div style={{ fontSize: 12, color: C.muted, marginBottom: 5 }}>{label}</div>
      {children}
    </label>
  );
}

function Table({ head, rows }: { head: React.ReactNode[]; rows: React.ReactNode[][] }) {
  return (
    <div style={{ overflowX: 'auto' }}>
      <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 13.5 }}>
        <thead>
          <tr>
            {head.map((h, i) => (
              <th key={i} style={{ textAlign: 'left', padding: '12px 14px', color: C.muted, fontWeight: 600, borderBottom: `1px solid ${C.border}`, whiteSpace: 'nowrap' }}>
                {h}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((r, ri) => (
            <tr key={ri}>
              {r.map((cell, ci) => (
                <td key={ci} style={{ padding: '12px 14px', borderBottom: `1px solid ${C.panel2}`, verticalAlign: 'middle' }}>
                  {cell}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function Tag({ children, color }: { children: React.ReactNode; color: string }) {
  return (
    <span
      style={{
        display: 'inline-block',
        padding: '2px 8px',
        borderRadius: 999,
        fontSize: 11,
        fontWeight: 700,
        color,
        background: `${color}22`,
        marginLeft: 6,
      }}
    >
      {children}
    </span>
  );
}

function Loading() {
  return <div style={{ ...card(), textAlign: 'center', color: C.muted }}>Loading…</div>;
}

function Empty({ msg }: { msg: string }) {
  return <div style={{ padding: 28, textAlign: 'center', color: C.muted, fontSize: 14 }}>{msg}</div>;
}

function ErrorBox({ msg }: { msg: string }) {
  return <div style={{ ...card(), color: C.red, borderColor: C.red }}>{msg}</div>;
}

/* ------------------------------------------------------------------ */
/* Style helpers                                                       */
/* ------------------------------------------------------------------ */

function card(pad = 18): React.CSSProperties {
  return { background: C.panel, border: `1px solid ${C.border}`, borderRadius: 16, padding: pad };
}

function input(): React.CSSProperties {
  return {
    width: '100%',
    padding: '10px 12px',
    borderRadius: 10,
    border: `1px solid ${C.border}`,
    background: C.panel2,
    color: C.text,
    fontSize: 14,
    outline: 'none',
    boxSizing: 'border-box',
  };
}

function btn(bg: string, color: string, small = false): React.CSSProperties {
  return {
    padding: small ? '6px 12px' : '9px 16px',
    borderRadius: 10,
    border: 'none',
    background: bg,
    color,
    fontSize: small ? 12.5 : 14,
    fontWeight: 700,
    cursor: 'pointer',
  };
}

function money(n: number) {
  return n.toLocaleString(undefined, { maximumFractionDigits: 2 });
}

function fmtDate(s: string | null) {
  if (!s) return '—';
  const d = new Date(s);
  return d.toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' });
}
