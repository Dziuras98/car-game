# Suzuka third-party asset permission record

## Asset identity

- asset: Suzuka circuit package for Assetto Corsa;
- source site: AssettoWorld;
- source page: https://www.assettoworld.com/track/suzuka;
- supplied archive name: `ac_suzuka_v.1.0.rar`;
- project conversion target: Godot 4.7 glTF/PNG track assets and runtime integration.

## Permission basis

On 2026-07-14, the project owner reported receiving information from the operators of AssettoWorld that files distributed through their site may be used, modified and redistributed for any purpose provided the use is noncommercial.

The repository relies on that statement for the noncommercial publication of the supplied Suzuka package and its converted derivatives. The statement is recorded as a source-specific permission, not as a Creative Commons license and not as a transfer of copyright or authorship.

The repository does not currently contain the original correspondence, screenshot or signed permission document. A copy should be retained if available, but absence of that copy does not change the project's record that permission was reported as obtained.

## Conditions applied by this project

The Suzuka source files and all direct converted derivatives:

- remain third-party materials originating from AssettoWorld;
- are excluded from the repository root `LICENSE`;
- may be used, modified and redistributed only for noncommercial purposes;
- must not be sold, monetized, included behind paid access, used in advertising-supported distribution, sponsored, or commercially licensed;
- must retain attribution to AssettoWorld and the source-page link;
- must not be presented as original assets authored by this project;
- must preserve this notice or equivalent terms in redistributed copies.

Project-authored integration code, import scripts, configuration and tests are separate works and remain governed by the repository's root license unless a file states otherwise.

## Required attribution

Use the following wording, or a substantially equivalent notice, wherever the converted track assets are redistributed:

> Suzuka circuit assets are third-party materials sourced from AssettoWorld: https://www.assettoworld.com/track/suzuka. They are used, modified and redistributed under permission reported by the project owner as allowing noncommercial use only. The assets are not original works of this project and are not covered by the project's root license. Commercial use is prohibited.

## Conversion modifications

The project conversion may include:

- extraction of Assetto Corsa KN5 geometry and embedded textures;
- conversion of visual geometry to glTF 2.0 and textures to PNG;
- splitting visual geometry into import-sized segments;
- grouping collision geometry by surface type;
- extracting and resampling the Assetto Corsa AI racing line;
- translating and rotating the circuit to the project's coordinate convention;
- creating Godot scenes, collision bodies, checkpoint gates and surface-grip metadata;
- technical optimization necessary for use in the project.

These modifications do not transfer authorship of the underlying circuit geometry, textures or source data to this project.

## Review triggers

The permission basis and publication decision must be reviewed before:

- commercial or monetized use;
- applying CC BY, CC BY-SA, CC BY-NC-SA or another standardized license to the assets;
- removing or materially weakening the noncommercial restriction;
- removing source attribution;
- receiving different terms from AssettoWorld or an identified track rights holder;
- responding to a copyright, trademark or takedown complaint.