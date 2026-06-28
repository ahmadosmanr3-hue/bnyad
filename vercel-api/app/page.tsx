export default function Home() {
  return (
    <main style={{ fontFamily: 'system-ui', padding: 24 }}>
      <h1>BNYAD API</h1>
      <p>Serverless API for the Nutrify Flutter app.</p>
      <p>
        Health: <a href="/api/up">/api/up</a>
      </p>
      <p>
        Admin panel: <a href="/admin">/admin</a>
      </p>
    </main>
  );
}
