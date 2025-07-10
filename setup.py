#!/usr/bin/env python3
"""
Setup script for Proof of Portfolio CLI.
"""

from setuptools import setup, find_packages

setup(
    name="proof-of-portfolio",
    version="1.0.0",
    description="Proof of Portfolio CLI",
    author="Inference Labs, Inc.",
    author_email="info@inferencelabs.com",
    packages=find_packages(),
    entry_points={
        "console_scripts": [
            "pop=src.main:main",
        ],
    },
    install_requires=[
        "numpy",
        "colorama",
    ],
    python_requires=">=3.6",
)
