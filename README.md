# mono-repo-template

This mono repo is intended to be used a catch-all for any type of software development for a given person, team, or organization.

The folder structure is intended to be used as follows:
- `apps` any code that will be built / shipped / deployed
- `packages` shared code, libraries, custom dependencies
- `docs` **GLOBAL** documentation, not app/package specific
- `scripts` **GLOBAL** scripts for easy repo setup / usage

The intention is for each app / package to be self contained.

If an app utilizes a repo level package then it should provide setup for how to link / setup for development.
