# Helm charts

This repository contains accelleran's helm charts.

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
