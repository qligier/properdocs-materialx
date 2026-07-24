# properdocs-materialx

A Docker image, built on Alpine Linux, bundling [ProperDocs](https://properdocs.org/) — the community-maintained 
successor to [MkDocs](https://www.mkdocs.org/) — with [MaterialX](https://github.com/jaywhj/mkdocs-materialx) — the 
community-maintained successor to [mkdocs-material](https://squidfunk.github.io/mkdocs-material/).

Together, `ProperDocs + MaterialX` are a drop-in, actively maintained replacement for
`MkDocs + mkdocs-material`, with full compatibility with the existing MkDocs ecosystem (plugins,
themes, and `mkdocs.yml` configuration files all keep working).

This image offers the same usage as
[`squidfunk/mkdocs-material`](https://github.com/squidfunk/mkdocs-material/blob/master/Dockerfile)
and [`jaywhj/mkdocs-materialx`](https://github.com/jaywhj/mkdocs-materialx/blob/main/Dockerfile):
same working directory, same exposed port, same command-line interface — just running on the ProperDocs engine 
instead of MkDocs.

## Image

- **Base**: `python:3.14-alpine3.24`
- **Installs**: [`properdocs`](https://pypi.org/project/properdocs/) and
  [`mkdocs-materialx`](https://pypi.org/project/mkdocs-materialx/) (theme `materialx`) from PyPI
- **Entrypoint**: `properdocs`, started via [`tini`](https://github.com/krallin/tini) for proper signal handling
- **Working directory**: `/docs`
- **Exposed port**: `8000` (development server)

## Usage

Pull the image:

```bash
docker pull qligier/properdocs-materialx
```

### Creating a new site

```bash
docker run --rm -it -v ${PWD}:/docs qligier/properdocs-materialx new .
```

This creates the following structure:

```
.
├─ docs/
│  └─ index.md
└─ properdocs.yml
```

### Live preview while writing

```bash
docker run --rm -it -p 8000:8000 -v ${PWD}:/docs qligier/properdocs-materialx
```

Point your browser to [localhost:8000](http://localhost:8000).
The default command is `serve --dev-addr=0.0.0.0:8000`, so running the image with no arguments starts the 
live-reloading development server.

### Building the static site

```bash
docker run --rm -it -v ${PWD}:/docs qligier/properdocs-materialx build
```

The generated `site/` directory is a self-contained static site that can be hosted anywhere (GitHub Pages, GitLab 
Pages, a CDN, or your own web server).

### Deploying to GitHub Pages

```bash
docker run --rm -it -v ${PWD}:/docs -v ~/.ssh:/root/.ssh qligier/properdocs-materialx gh-deploy
```

### Configuration file

ProperDocs looks for `properdocs.yml` (or `properdocs.yaml`) first, and falls back to `mkdocs.yml` (or `mkdocs.yaml`)
for backwards compatibility — so existing MkDocs projects work unmodified, without renaming anything.
To use the MaterialX theme, set in your configuration file:

```yaml
theme:
  name: materialx
```

## Versions

The exact `properdocs` and `mkdocs-materialx` versions installed into the image are pinned in
[`versions.env`](versions.env), the single source of truth for both the Dockerfile and the release workflow:

```
PROPERDOCS_VERSION=1.6.7
MATERIALX_VERSION=10.1.8
```

To upgrade, bump the versions in that file — the next build picks them up automatically, and the
release workflow tags the published image with the `MATERIALX_VERSION` value.

## Build arguments

The image can be customized at build time:

| Argument       | Default | Description                                                                           |
|----------------|---------|---------------------------------------------------------------------------------------|
| `WITH_PLUGINS` | `true`  | Installs `mkdocs-materialx` with its `recommended` and `imaging` extras when enabled. |

```bash
docker build --build-arg WITH_PLUGINS=false -t properdocs-materialx .
```

## Adding extra plugins

To add third-party plugins on top of this image, extend it with your own Dockerfile:

```dockerfile
FROM qligier/properdocs-materialx

RUN pip install --no-cache-dir mkdocs-awesome-pages-plugin mkdocs-git-revision-date-localized-plugin
```

Then build and use your own image the same way as described above.

## Releasing

The [release workflow](.github/workflows/release.yml) is triggered manually (`workflow_dispatch`).
It builds for `linux/amd64` and `linux/arm64` and pushes to Docker Hub, tagged from the semver `MATERIALX_VERSION` 
in [`versions.env`](versions.env):

- `latest`
- `X` (major)
- `X.Y` (major.minor)
- `X.Y.Z` (major.minor.patch)

It requires two repository secrets:

- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN` (a Docker Hub [access token](https://hub.docker.com/settings/security))

## Why ProperDocs and MaterialX?

MkDocs and mkdocs-material development stalled after their original maintainers stepped back, and the proposed 
replacements (a rewritten MkDocs 2.0 and the new [Zensical](https://zensical.org/) project) are incompatible with 
the existing ecosystem of plugins and themes.
ProperDocs (based on MkDocs 1.6.1) and MaterialX (based on mkdocs-material 9.7.1) are community-driven forks that keep
receiving updates and bug fixes while remaining fully compatible with existing configurations and plugins, at zero 
migration cost.

## License

This project only provides the Dockerfile packaging ProperDocs and MaterialX; it carries no license restrictions on 
its own beyond the license of its content below.
ProperDocs is distributed under the BSD license, and MaterialX under the MIT license.
See their respective repositories for details:

- [properdocs/properdocs](https://github.com/properdocs/properdocs)
- [jaywhj/mkdocs-materialx](https://github.com/jaywhj/mkdocs-materialx)
