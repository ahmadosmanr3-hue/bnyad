import fs from 'node:fs';
import http from 'node:http';
import { X509Certificate } from 'node:crypto';
import { privateLanAddress } from '../lib/local-development';

// Serves ONLY the public trust certificate, never a directory, key or credential.
// HTTP here bootstraps trust; the API itself is exclusively authenticated HTTPS.
const host = process.argv[2];
if (!host || !privateLanAddress(host) || process.env.VERCEL) throw new Error('Private LAN required.');
const publicCertificate = new X509Certificate(fs.readFileSync('.local-development/ca/rootCA.pem')).raw;
const profile = `<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><dict>
<key>PayloadContent</key><array><dict><key>PayloadCertificateFileName</key><string>bnyad-local-ca.cer</string>
<key>PayloadContent</key><data>${publicCertificate.toString('base64')}</data><key>PayloadDescription</key><string>Trust only for the private BNYAD development backend. Remove after testing.</string>
<key>PayloadDisplayName</key><string>BNYAD Local Test CA</string><key>PayloadIdentifier</key><string>com.bnyad.local-test.ca.certificate</string><key>PayloadType</key><string>com.apple.security.root</string><key>PayloadUUID</key><string>1E77E9D0-E0B3-4C70-9C74-7A15BCA25BE1</string><key>PayloadVersion</key><integer>1</integer></dict></array>
<key>PayloadDisplayName</key><string>BNYAD Local HTTPS Test Only</string><key>PayloadDescription</key><string>Contains one development root certificate. No device management, VPN, or accounts. Remove this profile after local testing.</string><key>PayloadIdentifier</key><string>com.bnyad.local-test.ca</string><key>PayloadType</key><string>Configuration</string><key>PayloadUUID</key><string>6F8DFD66-53A8-49F9-9396-7C4954BE3A32</string><key>PayloadVersion</key><integer>1</integer></dict></plist>`;
const server = http.createServer((req, res) => {
  if (!privateLanAddress(req.socket.remoteAddress?.replace(/^::ffff:/, '') ?? '') || req.headers.host !== `${host}:8766` || req.method !== 'GET' || !['/bnyad-local-ca.cer','/bnyad-local-ca.mobileconfig'].includes(req.url ?? '')) {
    res.writeHead(404); res.end(); return;
  }
  const configuration = req.url === '/bnyad-local-ca.mobileconfig';
  res.writeHead(200, { 'Content-Type': configuration ? 'application/x-apple-aspen-config' : 'application/x-x509-ca-cert', 'Cache-Control': 'no-store' });
  res.end(configuration ? profile : publicCertificate);
});
server.listen(8766, host, () => console.log(`Public test certificate only: http://${host}:8766/bnyad-local-ca.cer`));
setTimeout(() => server.close(), 60 * 60 * 1000);
