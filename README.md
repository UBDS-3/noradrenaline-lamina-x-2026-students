# Noradrenaline Lamina X 2026 — student repo

Welcome! This repository is the shared workspace for the UBDS^3 school project on
Noradrenaline signaling in Lamina X. This README explains how the repo is organized
and exactly how to work in it.

## One-time setup

1. **Accept your collaborator invite**
2. Clone the repo:

   ```bash
   git clone https://github.com/UBDS-3/Noradrenaline_Lamina_X_2026_students.git
   cd Noradrenaline_Lamina_X_2026_students
   ```

3. Create **your own branch** — replace `firstname` with your actual first name (lowercase, no spaces):

   ```bash
   git checkout -b student/firstname
   git push -u origin student/firstname
   ```

4. Open a **draft Pull Request** on GitHub:
   - Go to the repo → **Pull requests** → **New pull request**
   - Base: `main` ← Compare: `student/firstname`
   - Click **"Create draft pull request"**
   - Title it `Progress — Firstname`

   This PR is your personal progress log for the whole program — you don't need
   to "finish" anything to open it. Just get it open on day one.

## Daily workflow

Work only on your own branch:

```bash
git checkout student/firstname   # make sure you're on your branch
# ... edit files, run analysis, etc ...
git add .
git commit -m "Short description of what you did"
git push
```

Every push automatically updates your draft PR, so we can see your progress and
leave comments directly on your code.

## Getting updates from the shared repo

If we add new starter code, data, or instructions to `main`, sync them into your
branch like this:

```bash
git checkout student/firstname
git fetch origin
git merge origin/main
```

If there's a merge conflict, git will tell you which files are affected — open
them, resolve the conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`), then:

```bash
git add <resolved-file>
git commit
git push
```

Ask an instructor if you're unsure how to resolve a conflict — don't force-push
over it.

## Ground rules

- **Never commit** raw sensitive data, credentials, API keys, or `.env` files.
  Check `.gitignore` before adding new file types, and ask an instructor if unsure.
- **Don't push to `main`** — it's protected. All work happens on your `student/*`
  branch and shows up in your PR.
- Keep commits small and message them descriptively, it makes it much easier for
  us to follow your progress and give useful feedback.

## Getting help

- Comment directly on your PR (on specific lines of code, or general comments)
  we'll respond there.
- For anything urgent, ask us any time.

Good luck, and have fun with the project!