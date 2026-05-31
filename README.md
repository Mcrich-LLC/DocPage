# DocPage

DocPage is a small tool for making single-page DocC articles.

It takes a normal Markdown file and turns it into the DocC-style article JSON
used by Apple's documentation tooling. That makes it useful for quick docs
experiments, standalone article previews, and projects that want DocC article
data without setting up a full documentation archive.

It is also handy alongside [DocCKit](https://github.com/Mcrich-LLC/DocCKit),
since DocCKit can load and render this kind of article JSON. On macOS, DocPage
can open a small preview app after compiling so you can check the result right
away.

## Requirements

- Swift 6.0 or newer

## Install

Install DocPage with Homebrew:

```sh
brew tap Mcrich-LLC/formulae
brew install docpage
```

## Building

DocPage is a Swift package. From the project folder, build it with:

```sh
swift build
```

You can also run it directly with Swift Package Manager:

```sh
swift run docpage compile path/to/article.md
```

## Usage

Compile a Markdown file:

```sh
docpage compile article.md
```

By default, DocPage writes a JSON file using the same name as your Markdown file:

```sh
article.md -> article.json
```

Choose a different output path:

```sh
docpage compile article.md --output Docs/article.json
```

Open the preview app after compiling:

```sh
docpage compile article.md --preview
```

> [!Note]
> The preview app is only available on macOS. The first time you use `--preview`,
DocPage downloads the article viewer into `~/.docpage`.

## Using The Output

DocPage produces a single DocC article JSON file. You can use that file anywhere
that expects DocCa article data.

That makes DocPage useful for producing one-off documentation pages, remote content for apps (ie. What's New), etc.

If your article includes attached resources, especially images or other media,
use remote URLs when you plan to deploy the generated JSON. Local file paths may
work while previewing on your machine, but they will not be available to readers
once the page is hosted somewhere else.

## How It Works

DocPage creates a temporary Swift package, places your Markdown file inside a
DocC catalog, asks Swift DocC to build the documentation, then copies out the
generated article JSON.

The temporary package is deleted after the JSON is generated.

Your input file must be Markdown and use the `.md` extension.
