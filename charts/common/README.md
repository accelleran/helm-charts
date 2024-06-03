# Common library charts

This chart contains templates for commonly used objects within the helm charts.

## Template interface

All templates in helm have the limitation that only one argument can be provided as input and
a string will be given back as output.
In accelleran's common templates the input is always a dictionary with named arguments.
This allows to pass multiple arguments to accelleran's common templates.

There is only one required argument for all templates, namely `"top"`.
It's value should always be the root context of the chart, namely `$`.
In order to retain access to the root context it needs to be passed down.
Because within templates `$` will evaluate to the single passed down argument
instead of the root context.

Optionally, `"values"` can be provided as a second argument to all of the templates.
By default it will fall back to the `.Values` within the root context.
This is mostly useful to conditionally overwrite some values or provide subchart values.
Note that the value provided to `"values"` needs to contain "all the values".
So it's for example not possible to only provide the subset of values to overwrite:
it needs be merged together with the original values in that case.

Other arguments that are provided through the dictionary will depend on the template itself.

By using this structure consistently a user of these templates will know what to expect.
Also passing down arguments to dependendent templates becomes easy as this can be done with just a dot (`.`).

## Values interface

The common library charts will dictate what the values files look like for the application charts that use it.
For example the image for a container needs specific keys in the values file:

```yaml
image:
  repository: accelleran/cuup-netconf
  tag: ""
```

This structure should either be present in the root level of a chart or should be pointed to via the custom `values` argument.
In the case of the image tag it will also fall back to the `.Chart.AppVersion` when providing an empty string.
The tag in the values file is then present to allow overriding that value.
A deeper look into the templates will be needed to know what has defaults and what they are.

## Bootstrap hostnames

A chart using this common library chart can have a bootstrap section as part of it's values file interface.
Probably, it will (partially) look like this by default:

```yaml
bootstrap:
  create: true
  name: ""

  redis:
    hostname: ""
    port: 0

  nats:
    hostname: ""
    port: 0

  kafka:
    hostname: ""
    port: 0

redis:
  enabled: true
nats:
  enabled: true
kafka:
  enabled: true
```

The hostnames have empty values here though.
These will get default values assigned by the templates
as if these services are deployed as part of the same chart (the release name is injected then).
The bottom block of configuration would express this,
as the imported charts for redis, nats and kafka are all enabled.
In this case everything should be working perfectly fine.

The moment one of these services is not installed as part of the chart, the services would not be able to be brought up in a valid way.
This could happen when a user disables the service in the values provided at installation.
Or when the chart developer(s) decide to not include this dependency as part of their chart.

To warn for this scenario a failure message will be printed out when all of the following conditions hold true:

1. The bootstrap config is configured to be created (i.e. `bootstrap.create=true`)
1. The chart is not deploying (one of) the services (either because it's not part of the chart or because it's disabled).
1. The hostname is empty (also after evaluating templated values)

There are two ways to handle this:

1. The bootstrap configmap is created externally to the chart.
1. The hostname is filled in.

In the first case the values file disable the creation of the configmap and provide the external configmap's name:

```yaml
bootstrap:
  create: false
  name: "<the-external-bootstrap-configmap-name>"
```

In the second case the hostname is simply filled in for the external service provider:

```yaml
bootstrap:
  create: true
  name: ""

  redis:
    hostname: "<external-redis-hostname>"
  nats:
    hostname: "<external-nats-hostname>"
  kafka:
    hostname: "<external-kafka-hostname>"
```

The port is still optional here as it will fall back to the default port of the service.

> Note
>
> It might occur that this failure happens in a nested part of the values file.
> Therefore the chart name is included in the message to guide where the failure is happening exactly.
> `nameOverride` might add confusion here though as it allows to change the chart name.
