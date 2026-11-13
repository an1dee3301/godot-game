"""Compatibility entry point for the original Blender world build command.
The game now uses the single, coherent production showground.
"""
import pathlib, runpy
runpy.run_path(str(pathlib.Path(__file__).with_name("build_showground.py")),run_name="__main__")
