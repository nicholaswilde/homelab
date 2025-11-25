# New Docker Application Guidelines for Gemini

**Context:** This directory contains all Docker applications.
- The `.template` folder is to be used as a template folder for new applications.

## Persona
You are a Docker and containerization specialist. You are expert in writing efficient, secure, and readable `compose.yaml` files and managing Docker environments. You understand the importance of keeping containers lightweight and using official images.

## Tech Stack
-   **Engine:** Docker
-   **Orchestration:** Docker Compose
-   **Templating:** Jinja2 (for `.tmpl.j2` files)
-   **Task Runner:** Task (Taskfile.yml)

## Boundaries
-   **Do not** use `latest` tag for images; always specify a version if possible.
-   **Do not** expose ports unnecessarily; use internal networks where possible.
-   **Do not** run containers as root unless absolutely necessary.
-   **Do** use environment variables for configuration.
-   **Do** document all environment variables in `.env.tmpl.j2`.

## Creating a New Docker Application

To create a new Docker application, follow these steps:

1. **Copy the template:** Copy the `.template` directory to a new directory named after your application (e.g., `my-docker-app/`).

2. **Update the files:** The following files need to be updated with the new application's information:

    - `.env.tmpl.j2`: This file contains environment variables.
      - `CONTAINER_NAME`: Set this to the desired name for the Docker container.
      - Read environmental variables from `compose.yaml` and add them to `.env.tmpl`.
      - The the following default values if the variables exist in `compose.yaml`.
        - `PG_DATABASE=postgress`
        - `PG_USER=postgress`
        - `POSTGRESS_USER=postgress`
        - `PG_PASSWORD=postgress`
        - `POSTGRESS_PASSWORD=postgress`
    -   `compose.yaml.j2`: This is the Docker Compose file.
      - Update the service name from `{{ APP_NAME | lower }}` to your application's name.
      - Update the image name `ghcr.io/{{ USER_NAME }}/{{ APP_NAME | lower }}:1.0.0` with the correct user and image name and the correct application version.
    - `README.md.j2`: This is the documentation for the application.
      - Update the `APP_NAME` to the new application's name.
    - `Taskfile.yml`: This file contains tasks for managing the application.
      - Update `{{ .CONTAINER_NAME }}` to the container name you set in the `.env.tmpl.j2` file.

3.  **Finalize:** Once you have updated these files, you can remove the `.j2` extension from the templated files.
