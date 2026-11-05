import fs from 'node:fs';
import path from 'node:path';

// Import only RevenueCat PUBLIC SDK keys from the owner's existing private
// configuration. Server secrets and Gemini keys are deliberately never copied.
const source=process.argv[2];
if(!source||!path.isAbsolute(source)||!fs.existsSync(source))throw new Error('Supply an existing private Flutter configuration file.');
const text=fs.readFileSync(source,'utf8');
const android=text.match(/['"](goog_[A-Za-z0-9_-]+)['"]/)?.[1];
const ios=text.match(/['"](appl_[A-Za-z0-9_-]+)['"]/)?.[1];
if(!android||!ios||[android,ios].some(key=>key.length<20||/YOUR|PLACEHOLDER|EXAMPLE/i.test(key)))throw new Error('Both existing public SDK keys are required.');
const file=path.resolve('release-config.json');
const config={API_BASE_URL:'https://nutrify-api-lovat.vercel.app/api',RC_ANDROID_PUBLIC_KEY:android,RC_IOS_PUBLIC_KEY:ios};
fs.writeFileSync(file,JSON.stringify(config,null,2)+'\n',{mode:0o600,flag:'wx'});
console.log('Private release-config.json prepared with production API and public subscription SDK keys only. No Gemini key was copied.');
