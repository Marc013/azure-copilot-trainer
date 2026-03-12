---
title: GitHub Pages Setup
description: How to configure your GitHub repository to deploy the documentation site
---

# GitHub Pages Configuration

This documentation site is built with Hugo and deployed automatically via GitHub Actions to GitHub Pages.

## Quick Setup

### 1. Enable GitHub Actions (if not already enabled)

1. Go to your GitHub repository.
2. Navigate to **Settings › Actions › General**.
3. Under **Actions permissions**, select **Allow all actions and reusable workflows**.
4. Click **Save**.

### 2. Configure GitHub Pages

1. Go to **Settings › Pages**.
2. Under **Source**, select **GitHub Actions** from the dropdown.
3. Click **Save** (if prompted).

That's it! The workflow will automatically build and deploy on the next push to `main`.

## How It Works

The `.github/workflows/github-pages-hugo.yml` workflow:

1. **Triggers** on push to `main` (or manual trigger via **Actions** tab)
2. **Builds** the site from the `/docs` folder:
   - Installs dependencies: `npm install` (CSS tooling)
   - Runs Hugo: `hugo --gc --minify`
   - Outputs to `docs/_site/`
3. **Deploys** the `docs/_site/` folder to GitHub Pages

Your site appears at:
- **Default**: `https://<github-username>.github.io/<repo-name>/`
- **Custom domain**: Configure under **Settings › Pages › Custom domain** (if desired)

## Verifying the Deployment

1. Go to your repository **Actions** tab.
2. You should see a workflow run named "Deploy Hugo site to GitHub Pages".
3. Check the status:
   - ✅ **All green** = Site deployed successfully
   - ❌ **Red** = Build or deploy failed; check the workflow logs

4. Once deployed, visit your site URL to confirm it's live.

## Local Development

To preview the site locally before pushing:

```bash
cd docs
npm install
hugo server
```

Open `http://localhost:1313` in your browser. Changes auto-reload.

## File Locations

All site configuration and content is in the `/docs` folder:

```
docs/
├── hugo.toml                    # Hugo configuration
├── go.mod                       # Go module (Docsy theme dependency)
├── package.json                 # Node.js dependencies (CSS tooling)
├── postcss.config.js            # PostCSS configuration
├── .gitignore                   # Ignore build artifacts
├── content/                     # Content files (Markdown)
│   ├── _index.md               # Home page
│   └── how-to-use.md           # How To Use guide
├── layouts/                     # Overrides to Docsy theme
│   └── partials/
│       ├── navbar.html         # Custom navbar
│       └── footer.html         # Custom footer
└── _site/                       # Build output (generated, not committed)
```

## Customization

### Change Site Title

Edit `docs/hugo.toml`:

```toml
title = "Your New Site Title"
```

### Add New Pages

Create a new Markdown file in `docs/content/`:

```bash
cd docs/content
cat > new-page.md << 'EOF'
---
title: New Page Title
description: Brief description
---

# New Page Title

Your content here.
EOF
```

The page will appear at `/new-page/` on the site.

### Customize Theme

Edit theme settings in `docs/hugo.toml` under `[params]` and `[params.ui]`.

Override theme templates in `docs/layouts/` (e.g., `layouts/partials/navbar.html`).

## Troubleshooting

### Workflow fails with "No Hugo binary found"

The workflow uses `peaceiris/actions-hugo@v3`. Ensure you have Node.js 20+ and Go 1.22+ available.

### Site shows old content

1. Clear GitHub Pages cache: Go to **Settings › Pages** and toggle **Source** (off → GitHub Actions → back on).
2. Re-run the workflow manually from the **Actions** tab.

### CSS not loading

Hugo rebuilds CSS from PostCSS. Ensure `npm install` runs successfully in the workflow logs.

### Custom domain not working

1. Add `CNAME` file in `docs/static/CNAME` with your domain name.
2. Configure DNS records per [GitHub's custom domain guide](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site).

## Further Help

- [Hugo Documentation](https://gohugo.io/documentation/)
- [Docsy Theme Guide](https://www.docsy.dev/)
- [GitHub Pages Docs](https://docs.github.com/en/pages)
