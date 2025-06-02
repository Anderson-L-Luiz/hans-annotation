# Projects

Projects are generated from the main [`projects.json` file](projects.json) using the [`create_project_config.py` script](./../create_project_config.py).

It is important to keep the order of the `projects` array in the [`projects.json` file](projects.json)!

Each defined project could use webhooks defined in [`webhooks.json`](webhooks.json).

## Templates

[`projects.json` file](projects.json) contains a `type` field for each project.
The `type` key of each project refers to defined view types in [templates/template-types-views.json](./templates/template-types-views.json).
The `members` array contains names for view template members and their used templates.
The templates are defined [templates/templates.json](./templates/templates.json), e.g. concrete questions `asrError`.
The rendering is done by specific template types which are definded in [templates/template-types.json](./templates/template-types.json), e.g. `question`.

## Webhooks

The defined webhooks in [`webhooks.json`](webhooks.json) need to refer to the [`annotation-api` folder](./../../annotation-api/) flask implementation.
