// Copies the deployed web app's static files into www/ so `npx cap sync`
// has something to package into the native Android/iOS shells. There's no
// bundler here on purpose -- this project is one plain index.html, same as
// what's already live on GitHub Pages -- so "building" is just a file copy.
const fs = require('fs');
const path = require('path');

const root = path.join(__dirname, '..');
const webDir = path.join(root, 'www');

const files = [
  'index.html',
  'manifest.webmanifest',
  'sw.js',
  'icon-192.png',
  'icon-512.png',
  'apple-touch-icon.png',
  'favicon-32.png',
  'logo.png',
  'trulander-logo.png',
  'site-plan.jpg',
  'pipeline-template.xlsx',
  'contract-cover.jpg',
  'trulander-wordmark.png',
];

fs.rmSync(webDir, { recursive: true, force: true });
fs.mkdirSync(webDir, { recursive: true });

for (const file of files) {
  const src = path.join(root, file);
  if (!fs.existsSync(src)) {
    console.warn(`sync-web: skipping missing file ${file}`);
    continue;
  }
  fs.copyFileSync(src, path.join(webDir, file));
}

console.log(`sync-web: copied ${files.length} files into www/`);
