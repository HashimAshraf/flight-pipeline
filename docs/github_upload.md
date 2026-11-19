# Publish this project to your existing GitHub repository

This ZIP contains the project files, not a `.git` directory. Keep your existing Git history;
do not delete the `.git` folder in your local clone.

## Recommended: update the repository you already created

1. Open your existing repository on GitHub and copy its HTTPS URL.
2. If you already have the repository cloned, open that folder in VS Code. Otherwise:
   ```bash
   git clone https://github.com/YOUR-USERNAME/YOUR-REPOSITORY.git
   cd YOUR-REPOSITORY
   ```
3. Create a feature branch:
   ```bash
   git switch -c feature/complete-opensky-weeks-1-2
   ```
4. Copy the contents of this project folder into the cloned repository folder. Allow files
   to be replaced when prompted, but **do not replace or delete the clone's `.git` folder**.
5. Before staging, check that `.env` is not present:
   ```bash
   git status --short
   ```
   The `.env` file must remain local and ignored. Commit `.env.example`, not `.env`.
6. Stage and review:
   ```bash
   git add .
   git status
   git diff --cached
   ```
7. Commit and push:
   ```bash
   git commit -m "Complete OpenSky ETL and Airflow orchestration for weeks 1-2"
   git push -u origin feature/complete-opensky-weeks-1-2
   ```
8. On GitHub, open a Pull Request from that branch into `main`, review the changed files,
   and merge it when satisfied.

## If you have not created a GitHub repository yet

Create an empty repository on GitHub (do not initialize it with a README if you plan to
push an existing local project), then from the extracted project folder run:

```bash
git init
git branch -M main
git add .
git commit -m "Build OpenSky flight data ETL pipeline"
git remote add origin https://github.com/YOUR-USERNAME/YOUR-REPOSITORY.git
git push -u origin main
```

## Before pushing

- Confirm `.env` is ignored: `git check-ignore .env`
- Confirm no credentials are staged: `git status --short`
- Never paste OpenSky client secrets, database passwords, access tokens, or private keys
  into source files, commits, screenshots, or GitHub issues.
- Do not commit PostgreSQL data volumes, Airflow logs, virtual environments or `.pyc` files.

## Important

The project ZIP does not contain your repository's `.git` metadata and cannot push itself
to GitHub. The commands above publish it through your existing local clone and preserve
your repository history. If Git reports a merge conflict or rejected push, stop and inspect
the message rather than force-pushing.
