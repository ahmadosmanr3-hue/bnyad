import fs from 'node:fs';
import path from 'node:path';
import https from 'node:https';
import { parseEnv } from 'node:util';
import { assertLocalDevelopment, localLedgerDirectory, privateLanAddress } from '../lib/local-development';
import { localNetworkTransport, foodTestArmed } from '../lib/ai/supervised-food';

async function main() {
  if (process.env.VERCEL || process.env.NODE_ENV === 'production' || process.env.DATABASE_URL) throw new Error('Use a clean local-only process.');
  const directory = path.resolve('.local-development');
  const file = path.join(directory, 'backend.env');
  if (fs.lstatSync(file).mode & 0o077) throw new Error('Private local environment required.');
  Object.assign(process.env, parseEnv(fs.readFileSync(file, 'utf8')));
  assertLocalDevelopment(); localLedgerDirectory();
  if (process.env.BNYAD_LOCAL_AI_MODE !== 'mock') throw new Error('This server supports mock mode only.');
  // Only an explicitly claimed one-use food approval can cross this gate.
  // All other external fetches remain blocked; no global real key is loaded.
  globalThis.fetch = localNetworkTransport(globalThis.fetch);
  const host = process.env.BNYAD_LOCAL_LAN_ADDRESS!;
  if (!privateLanAddress(host)) throw new Error('Private LAN binding required.');
  const { default: next } = await import('next');
  const app = next({ dev: true, hostname: host, port: 8443 });
  await app.prepare();
  const handle = app.getRequestHandler();
  const server = https.createServer({ key: fs.readFileSync(path.join(directory, 'server-key.pem')), cert: fs.readFileSync(path.join(directory, 'server.pem')), minVersion: 'TLSv1.2' }, (req, res) => {
    const peer = req.socket.remoteAddress?.replace(/^::ffff:/, '') ?? '';
    if (!privateLanAddress(peer) || (req.headers.host !== `${host}:8443`)) { res.writeHead(403); res.end(); return; }
    // No development UI, admin, setup or debug routes exposed on the LAN.
    const pathname = (req.url ?? '').split('?')[0];
    if (!/^\/api\/(?:auth\/(?:login|logout|me|check-phone)|ai\/(?:consent|generate)|local-development\/readiness|profile|logs(?:\/[^/]+)?|water|weights|meal-plan|notifications|subscription)$/.test(pathname)) { res.writeHead(404); res.end(); return; }
    res.setHeader('X-Bnyad-Test-Mode', foodTestArmed() ? 'mock-with-one-use-food' : 'mock-no-google');
    void handle(req, res);
  });
  server.requestTimeout = 45000; server.headersTimeout = 15000;
  server.listen(8443, host, () => console.log(`BNYAD local-only HTTPS ready: https://${host}:8443/api; mocks by default; live food requires a private one-use approval.`));
}
main().catch(() => { console.error('Local HTTPS startup refused. Check private configuration and certificate files.'); process.exitCode = 1; });
