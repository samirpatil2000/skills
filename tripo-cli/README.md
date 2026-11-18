# Tripo CLI & 3D Engineering Skill

This skill equips agents with the knowledge and workflow patterns to generate, texture, rig, animate, segment, and assemble production-grade 3D assets using the **Tripo3D CLI** and **Blender**.

## Quick Highlights

- **Default Model**: `tripo-p2` (`P2-20260801`) for clean topology (48k tris / 25k quads).
- **H-Series Model**: `tripo-v3.1` (`v3.1-20260211`) for dense geometry and `generate_parts`.
- **Key Workflow**: **Modular Sub-Asset Decomposition** — generate individual components separately to maximize fidelity and avoid mesh fusion, then assemble and bake in Blender.
- **MCP Server**: Native support via `tripo mcp --toolset full`.

See [`SKILL.md`](./SKILL.md) for complete technical commands, recipes, and Blender assembly steps.
