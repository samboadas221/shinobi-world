# Procedural Village Generation Design & Zoning Specifications

This document outlines the procedural zoning, building distribution, and road material layout algorithms for the new `shinobi_world` map generator.

---

## 1. Organic Zoning Division

Rather than utilizing a rigid central crossroad or concentric rings, each village footprint is partitioned into **Three Core Functional Zones** plus an independent boundary placement for the Kage Office. 

```
+-------------------------------------------------------------+
|                      [ KAGE OFFICE ]                        | (Placed at boundary/edge)
+-----------------------------+-------------------------------+
|                             |                               |
|       MILITARY ZONE         |      COMMERCIAL ZONE          |
|  - Ninja Academy            |  - Central Market Stalls      |
|  - Training Fields          |  - Large Specialty Stores     |
|  - 1-5 Forbidden Libraries  |                               |
|                             |                               |
+-----------------------------+-------------------------------+
|                                                             |
|                      RESIDENTIAL ZONE                       |
|  - High/Low-Density Houses                                  |
|  - Rare Neighborhood Cloth/Hair Shops                       |
|                                                             |
+-------------------------------------------------------------+
```

### Zone Partitioning Algorithm
1. **Sub-Division**: The village's rectangular bounds are divided into three non-overlapping sector rectangles using random-weighted ratio splits (e.g., Residential gets 60% of the footprint, Military gets 25%, Commercial gets 15%).
2. **Kage Office Placement**:
   - The Kage Office does not belong to a specific zone center and can sit freely on the outer edge/periphery (e.g., against the north village boundary).
   - This allows it to act as a scenic backdrop or defensible administrative citadel, mirroring real-life military village designs.

---

## 2. Structure & Building Distribution by Zone

Every structure generated is snapped to the global `map.tile_size` (16x16 pixels) and assigned a specific zone tag.

### A. The Military Zone
Exclusively frequented by ninjas, this area acts as the training and defense headquarters.
* **Ninja Academy (1 per village)**: The largest footprint building in the zone.
* **Training Fields (Multiple)**: Non-blocking flat grid zones where players receive an EXP boost. Renders with sandy or light-brown textures.
* **Forbidden Libraries (1 to 5 per village)**: Guarded, high-security stone structures housing village *kinjutsus* (forbidden techniques). The count scales with the village size tier:
  - Tiers 1-2: 1 Library
  - Tier 3: 2-3 Libraries
  - Tiers 4-5: 4-5 Libraries

### B. The Commercial Zone
The compact business hub, designed as the smallest zone by area but dense with details.
* **Central Food Market**: A clustered $N \times M$ grid of tiny, low-profile food stalls and canvas-top stands selling food and provisions.
* **Surrounding Big Stores**: Large-footprint specialty shops enclosing the central market, including:
  - Weapons Store
  - Armor Store
  - Hairstyle Store
  - Shinobi Supply Store

### C. The Residential Zone
The primary living district for the village population.
* **Housing**: Placed according to village density archetypes (clustered small houses in Big Villages; spacious houses in Small Villages).
* **Rare Neighborhood Shops**: Scattered sparsely in the middle of housing blocks (e.g., a localized clothing store or barber shop) to mimic organic neighborhood growth. The ratio is limited to maximum 1 shop per 10 houses.

---

## 3. Road Network & Material Variations

We support two distinct procedural road materials: **Dirt Roads** and **Stone Roads**.

```
           +-----------------------------------------+
           |           Road Material Rules           |
           +--------------------+--------------------+
                                |
        Is it a Medium or Big village?
        /                              \
      YES                               NO
      /                                  \
- Medium: 50% Stone Road              - Dirt Roads Only
- Big: 100% Stone Road
```

### Local Village Roads
- **Material Rules**:
  - **Small/Minor Villages** (Tiers 1-2): 100% Dirt Roads.
  - **Medium Villages** (Tier 3): 50% chance of Stone Roads based on local config weight, otherwise Dirt.
  - **Large/Great Villages** (Tiers 4-5): 100% Stone Roads.
- **Trace Layout**:
  - Primary thoroughfares flow naturally through the village, connecting highway gates and weaving past the Commercial and Residential districts.
  - Local branching pathways split into alleys or neighborhood loops using organic pathfinder steps rather than strict grid crosses.

### Inter-Village Highways
Highways linking distant villages use the following material rules:
* **Dirt Highways**: Default material for global transit.
* **Stone Highways**: Used exclusively to connect two large/medium villages under two strict conditions:
  1. Both connected villages are configured with **Stone Roads**.
  2. The distance between the two villages is below a configured proximity threshold:
     $$d(A, B) < \text{stone\_highway\_threshold}$$
     *(This ensures advanced paved infrastructure is reserved for close, high-traffic regional partners).*
