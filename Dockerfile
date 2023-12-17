##### Stage 1 - Build the virtual environment
# Here come the Slow-changing things (project dependencies) 
FROM python:3.11-buster as builder

# Specify the poetry version
RUN pip install poetry==1.4.2

# Increase determinism by specying the poetry parameters
ENV POETRY_NO_INTERACTION=1 \
    POETRY_VIRTUALENVS_IN_PROJECT=1 \
    POETRY_VIRTUALENVS_CREATE=1 \
    POETRY_CACHE_DIR=/tmp/poetry_cache

# Streamlit can't be run from the root, so we have to set a WORKDIR
WORKDIR /app

# Get the Poetry files
COPY pyproject.toml poetry.lock ./

# Add a Readme, mandatory for the poetry run
RUN touch README.md

# Install Poetry
# Leave behind the Development recourses
# Don't include the root, application files are added later
# Delete the cache
RUN poetry install --without dev --no-root && rm -rf $POETRY_CACHE_DIR


##### Stage 2 - Create a runtime image, this one uses a slim version of python
# Here come fast-changing things (application code)
# The runtime image, used to just run the code provided its virtual environment
FROM python:3.11-slim-buster as runtime

# Reference the virtual environment installed in the previous stage
ENV VIRTUAL_ENV=/app/.venv \
    PATH="/app/.venv/bin:$PATH"

COPY --from=builder ${VIRTUAL_ENV} ${VIRTUAL_ENV}

# Keep layers small, so copy only the application files required for runtime
COPY streamlit_app ./streamlit_app

# Optional second poetry install, if there are scripts that need to be run
# RUN poetry install --without dev

EXPOSE 8501

HEALTHCHECK CMD curl --fail http://localhost:8501/_stcore/health

ENTRYPOINT ["streamlit", "run", "streamlit_app/sentiment.py", "--server.port=8501"]