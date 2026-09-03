# Mast v1 specification

## Purpose

Mast is a macOS desktop editor for blogs built from Markdown files. It edits post files on disk and shows the running blog beside the editor.

The first release targets writers who use a local content folder and a static-site generator or development server.

## Scope

Mast v1 supports these tasks:

- Open a blog project from a recent-project screen.
- Create `mast.toml` through a short setup flow when the project does not contain one.
- Edit a Markdown post in a plain-text editor.
- Save edits with autosave and `Command-S`.
- Start, restart, and stop a local development server.
- Show the server in a `WKWebView` preview.
- Follow a post when the preview navigates to a configured post route.
- Open posts and commands from the `Command-K` palette.
- Paste an image into the editor and save it beside the post.

Mast v1 does not include WYSIWYG editing, source control, deployment, a content API, or a general-purpose file explorer.

## Platform and application model

Mast v1 is a native macOS app built with SwiftUI. It uses `NSTextView` for Markdown editing and `WKWebView` for the preview.

The app stores its interface state locally. It never stores post content outside the selected project.

## Project configuration

Each project has a `mast.toml` file at the repository root. This file is the source of truth for server and content settings.

```toml
[server]
preset = "hugo"
command = "hugo server --port {port}"
url = "http://127.0.0.1:{port}"

[server.options.hugo]
drafts = true
future = false

[content.packages.blog]
path = "content/blog"
route = "/{path}"

[content.packages.docs]
path = "content/docs"
languages = ["pt", "en"]
route = "/{lang}/{path}"
```

### Server settings

The `[server]` table defines the local development server.

| Key | Type | Required | Description |
| --- | --- | --- | --- |
| `preset` | string | Yes | `vite`, `hugo`, or `custom`. |
| `command` | string | Yes | Command that starts the server. It can include `{port}`. |
| `url` | string | Yes | Preview URL. It can include `{port}`. |

Before the app starts the command, it selects an available local port and replaces every `{port}` placeholder. This avoids depending on server log output and avoids port conflicts.

The command runs from the project root. Mast keeps the editor available if the server fails. The command palette provides **Start server** and **Restart server**. Mast stops the server when you close or change the project.

### Presets

The setup flow detects and suggests a preset. It does not apply a preset without confirmation.

| Preset | Detection | Initial command | Options |
| --- | --- | --- | --- |
| `vite` | A `package.json` that uses Vite | A selected package script with a port argument | Script selection |
| `hugo` | `hugo.toml` or `config.toml` | `hugo server --port {port}` | Draft and future content |
| `custom` | No supported project detection | User-provided command | None |

The preset fills initial values only. You can edit `command` and `url` after setup. A preset-specific option table uses the form `[server.options.<preset>]`.

### Content packages

The `[content.packages]` table contains named content packages. Mast shows the package name.

| Key | Type | Required | Description |
| --- | --- | --- | --- |
| `path` | string | Yes | Content folder, relative to the project root. |
| `route` | string | Yes | Preview route template. It supports `{path}` and `{lang}`. |
| `languages` | array of strings | No | Ordered languages for every post in the package. |

Every post is a folder. A package without `languages` uses `index.md`. A package with `languages` uses `index.<language>.md`. The first language is the default language.

For the post folder `content/docs/guides/getting-started` in the `docs` package, `{path}` is `guides/getting-started`. For `index.en.md`, `{lang}` is `en`.

## Setup and project selection

The first screen lists recent projects, in the style of a document app. You can open a recent project or select another folder.

If a selected folder has no `mast.toml`, Mast opens setup. Setup asks for the project folder, content packages, server preset, command, and preview URL. It writes `mast.toml` only after you confirm the values.

Mast remembers each project's last post, cursor position, scroll position, preview visibility, and recent-project entry.

## Main window

The main window has an editor and a preview. The preview appears beside the editor by default.

The editor is a plain-text Markdown editor with a monospaced font and line numbers. Markdown syntax highlighting and LanguageTool integration are later work.

`Command-Shift-P` hides or shows the preview. When the preview is hidden, the editor uses the full window width.

## Navigation

`Command-K` opens the command palette. The palette is the primary navigation surface. It can open a post, open a recent project, start or restart the server, show or hide the preview, and open project settings.

The preview can navigate freely. When a preview URL matches a package `route`, Mast opens the matching post and language in the editor. When the URL does not match a post, such as a home or tag page, Mast keeps the current post open.

Mast does not show a permanent file tree in v1.

## Saving and external changes

Mast saves after a short debounce when you stop typing. `Command-S` saves immediately. The editor shows a small saved or saving state.

If the open file changes on disk and Mast has no local pending edit, Mast reloads the file. If it has a local pending edit, Mast asks you to keep the editor version, reload the disk version, or compare both versions.

## Image paste

When you paste an image, Mast saves the image in the open post folder and inserts a relative Markdown reference at the cursor.

Mast uses the source filename when clipboard metadata or image metadata supplies one. Otherwise, it uses `image-YYYY-MM-DD-HHMMSS.png`. The initial inserted text is `![](./FILENAME.png)`.

If the target filename exists, Mast asks whether to replace the existing file or save with another name. Mast never replaces an image without confirmation.

## Acceptance criteria

Mast v1 is ready when these flows work:

1. You can create a project configuration from setup and reopen it from recent projects.
2. You can open, edit, autosave, and immediately save an `index.md` or `index.<language>.md` file.
3. You can start a configured Vite, Hugo, or custom server on an app-selected port.
4. The preview loads the configured URL and hot reloads after a saved edit.
5. A matching preview navigation opens its configured post in the editor.
6. You can hide the preview, use the command palette, and paste an image without losing Markdown content.
