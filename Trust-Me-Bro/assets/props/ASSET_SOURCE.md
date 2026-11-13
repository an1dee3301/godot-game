# Original modeled party props

All four props were authored in Blender 5.2.2 through the checked-in source `tools/build_party_props.py`. Editable source is `tools/source/party_props.blend`. No external meshes, textures, generated images, generated video, or generative asset services were used.

| Asset | Triangles | GLB bytes | Materials |
| --- | ---: | ---: | ---: |
| answer_block.glb | 1,084 | 31,668 | 2 |
| banana.glb | 508 | 20,820 | 4 |
| smoke_bomb.glb | 1,076 | 45,216 | 4 |
| crown.glb | 2,568 | 123,968 | 4 |

Total: 221,672 bytes (216.5 KiB). Every prop is below 5,000 triangles. Asset origins are centered for the game's existing rigidbody/crown logic; no physics behavior is embedded in the GLB files.

The answer block's coated shell material is named `M_Answer` for runtime tinting. Cream letter panels extend to ±0.549 m, leaving room for gameplay labels at ±0.57 m. The banana is modeled as a thick crescent with peel facets and brown tips. The smoke bomb has a violet ball, modeled gold star and cotton fuse. The crown has a hollow gold circlet, six raised points, round finials and colored enamel gems.

Automated game-mesh QA passed for all four props with zero errors. Accepted warnings: centered assets extend below their local origin by design; answer-block panels retain their buried backs (104 hidden back-to-back face pairs) to keep reusable rounded panel geometry. All material surfaces were inspected in a Godot render. No missing textures or attribution requirements.
