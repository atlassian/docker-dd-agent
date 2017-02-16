#!/usr/bin/env python

import yaml
from cookiecutter.generate import generate_files

with open('custom_config/environment.yaml') as env_file:
    env = yaml.load(env_file)

context = { 'cookiecutter': env }

generate_files(
    repo_dir='custom_templates/',
    output_dir='custom_generated',
    context=context,
    overwrite_if_exists=True
)
