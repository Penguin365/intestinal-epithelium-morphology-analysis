#!/usr/bin/env python3
"""
BPA topology demo for ChipFrame simulation result.

This script reads one selected cell_data_time_*.dat file, converts cell
positions to a point-cloud PLY file, runs ball-pivoting reconstruction
using PyMeshLab, and writes a topology summary CSV.
"""

import argparse
import glob
import os
import re
import sys
from typing import Optional, Tuple

import numpy as np
import pandas as pd


def find_cell_file(run_folder: str, time_point: Optional[int] = None) -> Tuple[str, int]:
    """Find the selected or latest cell_data_time_*.dat file in one run folder."""
    pattern = os.path.join(run_folder, "cellData", "cell_data_time_*.dat")
    files = glob.glob(pattern)
    if not files:
        raise FileNotFoundError(f"No cell_data_time_*.dat files found under {run_folder}")

    matches = []
    for path in files:
        m = re.search(r"cell_data_time_(\d+)\.dat$", os.path.basename(path))
        if m:
            matches.append((int(m.group(1)), path))

    if not matches:
        raise FileNotFoundError("No parseable cell_data_time_*.dat filenames found")

    matches.sort(key=lambda x: x[0])

    if time_point is None:
        tp, path = matches[-1]
        return path, tp

    for tp, path in matches:
        if tp == time_point:
            return path, tp

    raise FileNotFoundError(f"Requested time point {time_point} not found in {run_folder}")


def dat_to_ply(dat_file: str, ply_file: str) -> int:
    """Convert one .dat file to ASCII point-cloud PLY using columns 3:5."""
    data = np.loadtxt(dat_file)
    if data.ndim == 1:
        data = data.reshape(1, -1)

    if data.shape[1] < 5:
        raise ValueError("cell_data file has fewer than 5 columns; cannot read xyz")

    coords = data[:, 2:5]
    os.makedirs(os.path.dirname(ply_file), exist_ok=True)

    with open(ply_file, "w", encoding="utf-8") as f:
        f.write("ply\n")
        f.write("format ascii 1.0\n")
        f.write(f"element vertex {coords.shape[0]}\n")
        f.write("property float x\n")
        f.write("property float y\n")
        f.write("property float z\n")
        f.write("end_header\n")
        for x, y, z in coords:
            f.write(f"{x:.6f} {y:.6f} {z:.6f}\n")

    return int(coords.shape[0])


def parse_run_label(run_folder: str) -> dict:
    """Parse run_id and parameter tokens from folder name if present."""
    run_id = os.path.basename(os.path.normpath(run_folder))
    out = {
        "run_id": run_id,
        "NCI": np.nan,
        "SR": np.nan,
        "TP": np.nan,
        "GlobalIR": np.nan,
    }

    m = re.search(r"NCI_(\d+)_SR_([\d.]+)_TP_([\d.]+)_GlobalIR_([\d.]+)", run_id)
    if m:
        out["NCI"] = float(m.group(1))
        out["SR"] = float(m.group(2))
        out["TP"] = float(m.group(3))
        out["GlobalIR"] = float(m.group(4))

    return out


def run_bpa(point_ply: str, mesh_output: str, ball_radius: float):
    """Run PyMeshLab ball pivoting and return MeshSet."""
    try:
        import pymeshlab as ml
    except ImportError as exc:
        raise ImportError(
            "pymeshlab is required for BPA topology measurement. "
            "Install it in your Python environment before running this script."
        ) from exc

    ms = ml.MeshSet()
    ms.load_new_mesh(point_ply)
    ms.compute_normal_for_point_clouds(k=10)
    ms.generate_surface_reconstruction_ball_pivoting(
        ballradius=ml.AbsoluteValue(float(ball_radius))
    )

    os.makedirs(os.path.dirname(mesh_output), exist_ok=True)
    ms.save_current_mesh(mesh_output)
    return ms


def get_topology(ms) -> dict:
    """Extract topology metrics from reconstructed mesh."""
    topo = ms.get_topological_measures()

    vertices = topo.get("vertices_number", np.nan)
    edges = topo.get("edges_number", np.nan)
    faces = topo.get("faces_number", np.nan)
    components = topo.get("connected_components_number", np.nan)
    boundary_edges = topo.get("boundary_edges", np.nan)
    genus = topo.get("genus", np.nan)
    holes = topo.get("number_holes", np.nan)

    status = "ok"
    notes = "Topology extracted from PyMeshLab output."

    if np.isnan(holes):
        status = "partial"
        notes = "number_holes was not available from PyMeshLab output."

    bpa_pass = 1 if holes == 1 else 0

    return {
        "components": components,
        "holes": holes,
        "genus": genus,
        "boundary_edges": boundary_edges,
        "vertices": vertices,
        "edges": edges,
        "faces": faces,
        "bpa_pass": bpa_pass,
        "topology_status": status,
        "notes": notes,
    }


def write_summary(record: dict, output_csv: str):
    """Write one-row topology summary CSV."""
    os.makedirs(os.path.dirname(output_csv), exist_ok=True)
    df = pd.DataFrame([record])
    preferred_cols = [
        "run_id",
        "time_point",
        "days",
        "NCI",
        "SR",
        "TP",
        "GlobalIR",
        "components",
        "holes",
        "genus",
        "boundary_edges",
        "vertices",
        "edges",
        "faces",
        "bpa_pass",
        "topology_status",
        "notes",
    ]
    cols = [c for c in preferred_cols if c in df.columns]
    df = df[cols]
    df.to_csv(output_csv, index=False)


def main():
    parser = argparse.ArgumentParser(description="BPA topology demo for one ChipFrame run")
    parser.add_argument("--input", required=True, help="Path to one simulation run folder")
    parser.add_argument("--output", default="demo_output/bpa_topology_measurements.csv", help="Output CSV path")
    parser.add_argument("--time-point", type=int, default=None, help="Optional exact time point")
    parser.add_argument("--mesh-output", default="demo_output/bpa_mesh.ply", help="Output mesh path")
    parser.add_argument("--ball-radius", type=float, default=1.0, help="Ball radius for BPA")
    args = parser.parse_args()

    run_folder = os.path.abspath(args.input)
    if not os.path.isdir(run_folder):
        raise FileNotFoundError(f"Input run folder not found: {run_folder}")

    # Resolve output paths relative to Analysis_demo root.
    script_dir = os.path.dirname(os.path.abspath(__file__))
    demo_root = os.path.dirname(script_dir)

    output_csv = args.output
    if not os.path.isabs(output_csv):
        output_csv = os.path.join(demo_root, output_csv)

    mesh_output = args.mesh_output
    if not os.path.isabs(mesh_output):
        mesh_output = os.path.join(demo_root, mesh_output)

    point_cloud_ply = os.path.splitext(mesh_output)[0] + "_pointcloud.ply"

    # Read selected time point, then build point cloud for BPA reconstruction.
    dat_file, time_point = find_cell_file(run_folder, args.time_point)
    n_points = dat_to_ply(dat_file, point_cloud_ply)
    ms = run_bpa(point_cloud_ply, mesh_output, args.ball_radius)

    topo = get_topology(ms)
    meta = parse_run_label(run_folder)

    record = {
        **meta,
        "time_point": int(time_point),
        "days": float(time_point) / 2400.0,
        **topo,
    }

    if topo["notes"]:
        record["notes"] = f"{topo['notes']} Point cloud vertices: {n_points}."

    # Write summary in CSV.
    write_summary(record, output_csv)

    print(f"Input run: {run_folder}")
    print(f"Data file: {dat_file}")
    print(f"Mesh file: {mesh_output}")
    print(f"Summary CSV: {output_csv}")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        raise
