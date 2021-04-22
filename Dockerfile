FROM jupyter/minimal-notebook

RUN pip install jupyterlab tensorflow && \
    jupyter serverextension enable --py jupyterlab --sys-prefix

EXPOSE 8888
WORKDIR /work
CMD ["jupyter", "lab"]
