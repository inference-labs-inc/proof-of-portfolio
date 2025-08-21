# This file makes the src directory a Python package

import os
import shutil
from functools import wraps

_dependencies_checked = False


def ensure_dependencies():
    """Ensure bb and nargo are installed before running package functions."""
    global _dependencies_checked

    if (
        _dependencies_checked
        or os.environ.get("CI")
        or os.environ.get("POP_SKIP_INSTALL")
    ):
        return

    missing_deps = []
    if not shutil.which("bb"):
        missing_deps.append("bb")
    if not shutil.which("nargo"):
        missing_deps.append("nargo")

    if missing_deps:
        print(f"Installing required dependencies: {', '.join(missing_deps)}...")
        print("This may take a few minutes on first run.")

        try:
            from .post_install import main as post_install_main

            post_install_main()
            print("Dependencies installed successfully!")
        except Exception as e:
            print(f"Warning: Failed to install dependencies: {e}")

    _dependencies_checked = True


def requires_dependencies(func):
    """Decorator to ensure dependencies are installed before running a function."""

    @wraps(func)
    def wrapper(*args, **kwargs):
        ensure_dependencies()
        return func(*args, **kwargs)

    return wrapper
