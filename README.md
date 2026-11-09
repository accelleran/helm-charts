# Helm charts

This repository contains accelleran's helm charts.

## Chart lifecycle

Charts live in one of three top-level directories:

| Directory | Renovate | Lint | Install tests | Releases |
| --- | --- | --- | --- | --- |
| `charts/` | All updates | Yes | Yes (unless `.ct-install-ignore`) | Yes |
| `deprecated/` | First-party images (`accelleran/`, `firecell/`) and dependencies from `accelleran.github.io/helm-charts` | Yes | No | Yes |
| `archived/` | None | No | No | No |

Published artifacts (GitHub Releases, `index.yaml`, GHCR) are never deleted when a chart moves between tiers.

### Deprecate a chart

```sh
./bin/deprecate-chart -s <successor> <name>
```

`bin/deprecate-chart` moves `charts/<name>` to `deprecated/<name>` and:

- renames the package key in `etc/release-please-config.json` and `etc/.release-please-manifest.json` from `charts/<name>` to `deprecated/<name>` (`component` and `package-name` stay the same, so release tags stay continuous)
- sets `deprecated: true` in `Chart.yaml` and prefixes `description` with `DEPRECATED -`
- adds a `DEPRECATED` banner to `templates/NOTES.txt`, naming the successor when `-s` is set

`-s` is optional. Pass `--no-metadata` to leave `Chart.yaml` and `templates/NOTES.txt` unchanged. The chart still moves to `deprecated/`, so Renovate, lint, and install tests follow that tier, while installs keep the existing description and notes. Pass `-n` to show the move and release-please change without writing files. The script stages its changes and leaves the commit to you. Merge, and chart-releaser publishes the deprecation release.

### Archive a chart

```sh
./bin/archive-chart <name>
```

`bin/archive-chart` moves `deprecated/<name>` (or `charts/<name>`, which skips the deprecation release) to `archived/<name>` and removes that chart from the release-please config and manifest. Published releases and GHCR packages are left alone. Pass `-n` to print the plan without changing files.

To un-archive, reverse the steps and restore the release-please entries.

External charts (`charts/*/External.yaml`) are not deprecated in place: stop republishing by deleting the `External.yaml` directory.

## Releases

Depending on the type of release (an official release or release candidate), a different approach should be taken.

Every time a commit is pushed to a release branch (including `main`) helm's chart releaser will try to create a release of all charts.
It will block this if the specified version in the `Chart.yaml` file already matches with an existing release.
This allows to add multiple features to a single release and prevents from overwriting an existing one.

The above mechanism can then be used to create non-official releases by just manually bumping the version.
Note that this should only be done for release candidates, alpha, beta or dev releases!
If official releases were to be created this way, release please and the changelog would get out of sync.

With official releases everything is automated with release please.
Release please will create a PR which bumps the version and adds a changelog.
After someone of the drax team approved this PR it can be merged.
Helm's chart releaser will then run and it will use the changelog in the github release.
Note that, before a PR can be merged, some merge conflicts might need to be resolved if a release candidate was created.

## Chart dependencies

For helm chart dependencies the required repository needs to be added.
In case a new dependency repository is needed it should be added to `bin/add-repos`.
Otherwise the workflow will be broken as helm would be unable to build the chart dependencies.

To locally add all necessary repos:

```sh
./bin/add-repos
```

During development it's also possible to test the chart locally.
To add/update the local dependencies needed for that, the `bin/update-deps` script can be used.

```sh
./bin/update-deps
```

In case it's desired to also package up all helm charts and add them to the parent charts for testing,
then a flag can be added to the script:

```sh
./bin/update-deps -l
```

This is for example handy during development on the `common` library chart.

## External charts

It is possible to republish an upstream OCI chart into this repository's Helm
repo and GHCR without unpacking or re-packaging it.

Create a directory under `charts` that contains only `External.yaml`:

```yaml
name: example-chart
repository: oci://ghcr.io/example/charts
version: 0.1.0
notes:
  github: example/example
  tag: "v{{ version }}"
```

The version must be exact (ranges such as `0.1` are not supported).
Renovate bumps `version` when a newer chart is published upstream.

On release, the original `.tgz` is pulled into `.cr-release-packages` and
chart-releaser uploads it as a GitHub release and merges it into
`index.yaml`. The upstream OCI artifact is copied to
`oci://ghcr.io/accelleran/charts` so the GHCR digest matches upstream. The
chart keeps its upstream name and version.

`alias` is not supported: renaming a chart requires rewriting `Chart.yaml`
and would produce a new tarball. Published names must be unique across
first-party `Chart.yaml` and `External.yaml`; CI fails on a collision.

### Release notes

`notes:` copies the body of a GitHub Release onto the republished chart.
That is the only remote source. `notes.tag` is expanded against the
pulled chart's `Chart.yaml`:

| Placeholder | Value |
| --- | --- |
| `{{ name }}` | chart name |
| `{{ version }}` | chart version |
| `{{ appVersion }}` | chart `appVersion` |

If `notes:` is omitted, the GitHub release body stays as the upstream
`description` that chart-releaser already uses.

## New charts

A bit of setup is needed for release please when adding a new chart.
This is automated in `bin/add-chart`.

```sh
./bin/add-chart example 0.1.0
```

> The initial version is optional (default is `0.1.0`).

> **Note**
>
> When adding a new chart, the chart releaser action will always create an initial release without release please intervening.
> This means that the automatic changelog etc. will be missing in this initial GitHub release.
> Instead, chart releaser will use the description in `Chart.yaml` as the body of the GitHub release.

## Legacy charts

To add legacy helm charts, they need to be added to a release with the packaged chart as an asset.
This asset then needs to be linked to the `index.yaml` file for GitHub Pages.

The `release-legacy-chart` script expects either a directory of packaged charts or a single file (i.c.w. an index file).
The release tag etc. are derived from the file name.

```sh
 export GITHUB_TOKEN=abc-xyz

./bin/release-legacy-chart -f example-0.1.0.tgz -i index.yaml
./bin/release-legacy-chart -d charts
```

> Note the space to hide the token from history.
