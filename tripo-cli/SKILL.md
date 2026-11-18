---
name: tripo-cli
description: >
  Generate and process production-ready 3D assets with the Tripo3D CLI (`tripo`).
  Use when creating 3D models from text/images/multiview, texturing (PBR, delighting),
  auto-rigging (biped, quadruped, Mixamo/Unity/Unreal specs), animating with presets,
  retopology/decimation, mesh segmentation, and executing modular sub-asset decomposition
  workflows for Blender assembly.
---

# Tripo CLI & 3D Asset Engineering Guide

The `tripo` CLI is the official command-line interface and automation tool for Tripo3D AI. It converts text prompts, reference images, or multiview image sets into engine-ready 3D models (`GLB`, `FBX`, `OBJ`, `STL`, `USDZ`), with automated PBR texturing, rigging, animation retargeting, mesh segmentation, and retopology.

---

## 1. Quick Status & Verification

```bash
# Check logged-in user, key, and credit balance
tripo whoami

# Check credit balance & frozen tokens
tripo balance

# Diagnose environment, network, and active profile
tripo doctor
```

- **Default Region**: `ov` (international - developers.tripo3d.ai).
- **Config Storage**: `~/.tripo/config.json` (mode 0600).
- **Environment Override**: `export TRIPO_API_KEY="tsk_..."`

---

## 2. Core Tripo Architecture & Capabilities

### Generation Models

| Model Alias | Wire Version | Type | Best For | Notes |
|---|---|---|---|---|
| `tripo-p2` | `P2-20260801` | **Default** | Game assets, clean topology, low-poly | 48–50k tri / 48–25k quad. Clean edge loops. 100–130 credits. |
| `tripo-v3.1` | `v3.1-20260211` | Dense H-Series | Sculpting, dense details, parts generation | Supports `generate_parts`, `smart_low_poly`, `geometry_quality=detailed`. |
| `tripo-p1` | `P1-20260311` | Economy | Fast low-cost prototyping | 50–20k tri. Lower credit cost. |

> **Rule:** The CLI defaults to `tripo-p2` for all 3D generations unless explicitly overridden with `--model tripo-v3.1`.

### Scenario Presets (`--for`)

The `tripo make` command includes tuned pipelines via `--for <preset>`:
- `game-pc`: Optimized topology, PBR textures, standard game scale.
- `game-mobile`: Aggressive low-poly count, compressed textures.
- `film`: Maximum texture resolution and geometric fidelity.
- `print`: Watertight manifold mesh, flattened bottom, STL/3MF ready.
- `anim`: Automatic rig check, skeleton generation, and test motion.
- `ar-web`: Lightweight GLB/USDZ format with optimized UVs.

---

## 3. High-Level Commands Reference

### Generation (`tripo make` & `tripo generate`)

```bash
# Text to 3D model
tripo make "a futuristic cybernetic helmet, clean white ceramic and carbon fiber" --for game-pc --json --yes

# Image to 3D model
tripo make concept_art.png --for game-pc --json --yes

# Multiview (2 to 4 angles: front, back, left, right)
tripo make front.png back.png --for film --json --yes

# Continue from last generated task and chain post-processing
tripo make @last --then convert:fbx --json --yes
```

### Texturing (`tripo model texture`)

```bash
# Generate PBR maps (Roughness, Metallic, Normal) on existing task
tripo make <task_id> --then texture:pbr=true --json --yes

# Re-texture an imported mesh with prompt guidance
tripo model texture hero.glb -p pbr=true -p 'texture_prompt={"text":"weathered oxidized bronze"}' --json
```

### Rigging & Animation (`tripo anim`)

```bash
# 1. Rig check (determines if mesh is riggable and detects body type: biped, quadruped, etc.)
tripo anim check @last --json

# 2. Auto-rigging with specific skeleton standard
# Specs: mixamo | unity | unreal | actorcore | vrm
tripo anim rig @last --rig-type biped --spec mixamo --out-format fbx --json

# 3. Retarget motion from 90+ animation presets
# Presets: preset:walk, preset:run, preset:idle, preset:jump, preset:slash, preset:shoot, etc.
tripo anim retarget @last --animation preset:walk --out-format fbx --json
```

### Mesh Operations (`tripo mesh`)

```bash
# Retopology / Decimation
tripo mesh decimate @last --face-limit 5000 --model v3.0 --smart-uv --json

# Semantic Segmentation (splits a single mesh into individual labeled parts)
tripo mesh segment @last --model v2.0-20260430 --json

# Complete / Inpaint missing geometry on segmented pieces
tripo mesh complete <segment_task_id> --completion-mode ai_completion --json

# End-to-end auto segmentation from an image
tripo mesh smartsegment prop_photo.png --granularity fine --json
```

---

## 4. The Golden Workflow: Modular Sub-Asset Decomposition

### The Problem with Monolithic AI 3D Generation
Generating a complex asset as a single prompt (e.g., *"a mech warrior with shoulder cannons, gatling gun arm, and cockpit shielding"*) frequently results in:
1. **Fused geometry**: Cannon barrels fuse into shoulder armor; fingers melt into weapons.
2. **Texture bleeding**: Decals and material definitions blur across junctions.
3. **Articulation failure**: Cannot articulate joints or animate rotating turrets/limbs.
4. **Resolution dilution**: The 50,000 polygon budget is distributed across the entire asset instead of fine details.

### The Solution: Modular Breakdown & Blender Assembly

```
+-------------------------------------------------------------+
|                      MASTER CONCEPT                         |
|            (e.g., Sci-Fi Heavy Tank / Robot)                |
+-------------------------------------------------------------+
                              |
       +----------------------+----------------------+
       |                      |                      |
       v                      v                      v
[ Sub-Asset A ]        [ Sub-Asset B ]        [ Sub-Asset C ]
 Chassis / Body          Turret / Head          Treads / Wheels
 (tripo make ...)       (tripo make ...)       (tripo make ...)
       |                      |                      |
       +----------------------+----------------------+
                              |
                              v
                  [ Format Conversion to FBX ]
                   (--fbx-preset blender)
                              |
                              v
                 [ BLENDER DCC ASSEMBLY ]
   * Import components into separate Collections
   * Snapping & Transform alignment (Pivots at origin)
   * Boolean / Join (`Ctrl+J`) or Parent Hierarchies
   * Texture Atlas / Material baking (Single draw call)
```

---

## 5. Step-by-Step Modular Asset Execution Guide

### Step 1: Deconstruct into Logical Sub-Assets
Split the asset into discrete structural units:
- **Characters**: Torso/Chestplate, Helmet/Head, Arms/Gauntlets, Legs/Boots, Weapon/Shield.
- **Vehicles/Mechs**: Hull/Cockpit, Engine/Thrusters, Weapon Systems/Guns, Mobility (Tracks/Wheels/Legs).
- **Architecture**: Modular wall tiles, Door frame, Roof trim, Prop decorations.

### Step 2: Generate Each Sub-Asset Individually
Use consistent style descriptors and prompt framing for every component:

```bash
# 1. Base / Hull
tripo make "sci-fi combat mech armored cockpit and core torso, mechanical mounting points, modular hardpoints, white and charcoal armor, clean orthographic" \
  --for game-pc --model tripo-p2 --json --yes

# 2. Mobility / Legs
tripo make "pair of heavy hydraulic bipedal mech robotic legs, mechanical pistons, industrial suspension, neutral stance" \
  --for game-pc --model tripo-p2 --json --yes

# 3. Weapons / Arms
tripo make "heavy mechanical gatling cannon arm for robot, ammo feed system, modular hardpoint connector" \
  --for game-pc --model tripo-p2 --json --yes
```

### Step 3: Export with Blender-Optimized Transforms
Ensure models have compatible forward axis, pivots, and scaling:

```bash
# Convert to FBX with Blender preset
tripo model convert <task_id> \
  --format FBX \
  --fbx-preset blender \
  --texture-size 2048 \
  --pivot-to-center-bottom \
  --json --yes
```

### Step 4: Blender Assembly Pipeline

1. **Importing**:
   - In Blender, go to `File > Import > FBX`.
   - Each sub-asset imports cleanly with baked textures connected to Principled BSDF nodes.

2. **Alignment & Snapping**:
   - Set 3D Cursor to origin (`Shift + C`).
   - Use Vertex Snapping (`Shift + Tab`, snap to `Vertex`) to snap hardpoints and mounting sockets together.
   - Adjust scale uniformly across pieces.

3. **Hierarchy vs. Merging**:
   - **For Animated/Rigged models (e.g. Turret, Mechs)**: Keep sub-assets separate. Use Object Parenting (`Ctrl + P > Object (Keep Transform)`) so parts rotate around their mounting pivots.
   - **For Static Game Props (e.g. weapons, statuary)**: Select all sub-assets and join into a single mesh with `Ctrl + J`. Run `Edit Mode > Mesh > Clean Up > Merge by Distance`.

4. **UV Packing & Texture Baking**:
   - If a single draw call is required for a game engine, use Blender's texture baking:
     1. Create a second UV map on the merged object (`UVMap_Combined`).
     2. Unwrap all parts into one UV atlas (`UV > Pack Islands`).
     3. Bake Diffuse, Roughness, and Normal from original materials onto a single 2K/4K map.

---

## 6. Alternative In-Tripo Segmentation

If you already have a single master asset and want to break it down without modeling from scratch:

1. **Native Parts Generation on H-Series (`tripo-v3.1`)**:
   ```bash
   tripo generate text-to-model "a knight in full plate armor" \
     --model tripo-v3.1 \
     -p generate_parts=true \
     -p texture=false \
     --json --yes
   ```
2. **Semantic Mesh Segmentation**:
   ```bash
   # Segments model into labeled semantic parts (e.g., head, torso, limbs)
   tripo mesh segment <task_id> --model v2.0-20260430 --json
   
   # Export only individual components:
   tripo model convert <segment_task_id> --format FBX -p 'part_names=["chest_armor"]' --json
   ```

---

## 7. Model Context Protocol (MCP) Integration

Tripo CLI can run directly as an MCP server for AI coding agents:

```bash
# Start MCP server over stdio
tripo mcp

# Start with full toolset (includes tripo_download, texture guidance)
tripo mcp --toolset full
```

Available MCP Tools:
- `tripo_make`: Text/image/multiview generation and chaining.
- `tripo_task_get` & `tripo_task_wait`: Query and watch asynchronous tasks.
- `tripo_balance`: Monitor credit budget.
- `tripo_history`: Access recent task history.

---

## 8. Operational Rules & Gotchas

- **Non-Interactive Automation:** Always pass `--yes` and `--json` when scripting or delegating tasks to prevent CLI interactive confirmation prompts from blocking.
- **Unbuffered Logging:** When streaming or capturing long-running task outputs to a file, always use `| tee output.txt` (never raw `> output.txt`) to avoid POSIX block-buffering delays.
- **Credit Pre-flight:** Check `tripo balance` before spawning multi-component generation jobs.
- **Pivot Consistency:** For Blender assembly, always convert using `--fbx-preset blender --pivot-to-center-bottom` so origins match for snapping.
- **Log Papercuts:** If a Tripo CLI command fails, times out, or encounters unexpected mesh fusion or topology errors, record it to `PAPERCUTS.md` using the `papercut` / `log-papercuts` skill.

