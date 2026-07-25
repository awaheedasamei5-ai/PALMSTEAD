# PEP Landbank Sales Portal

This folder is ready to become your GitHub repo. Do this **once**, then updates become effortless.

## One-time setup (about 5 minutes)

### 1. Create the GitHub repo
- Go to github.com → New repository → name it (e.g. `pep-landbank-portal`) → Create.
- On your computer, in this folder, run:
  ```
  git init
  git add .
  git commit -m "Initial version"
  git branch -M main
  git remote add origin https://github.com/YOUR_USERNAME/pep-landbank-portal.git
  git push -u origin main
  ```
  (No terminal? You can also drag every file in this folder directly into the GitHub web page — click "uploading an existing file" on your new repo's page.)

### 2. Connect Netlify to the repo (this is what makes updates automatic)
- Go to app.netlify.com → Add new site → **Import an existing project** → choose GitHub → pick this repo.
- Build settings: leave build command empty, publish directory = `/` (root). Click Deploy.
- From now on: **any push to this repo automatically redeploys your live site within about a minute.** No more dragging files manually.

### 3. Supabase
Already connected and live — I've been applying database changes directly to your project (`lrahgcnftetnyxunaljs`) all session. Nothing to set up here. The `supabase_migrations/` folder in this repo is a record of every SQL change, kept for your reference — the database itself is already up to date.

## How updates work after this
1. You ask me for a change in this chat.
2. I hand you the updated `index.html` (and any new SQL, applied directly to Supabase).
3. You replace `index.html` in your local repo folder and run:
   ```
   git add .
   git commit -m "update"
   git push
   ```
   (or drag the new file into GitHub's web UI and commit — no terminal needed)
4. Netlify redeploys automatically. Nothing else to touch.

This never touches your live site directly and never risks downtime from a bad manual drag-and-drop — Netlify keeps every previous deploy and lets you roll back instantly from its dashboard if anything ever looks wrong.
