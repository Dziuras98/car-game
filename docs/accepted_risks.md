# Accepted project risks

## Third-party 370Z model provenance

Decision date: 2026-07-12

The project owner has reviewed the provenance limitation documented in `THIRD_PARTY_NOTICES.md` for the standard and NISMO Nissan 370Z GLB assets and has decided to retain both models.

The decision is based on the following project constraints:

- no practical replacement models are currently available at the required quality;
- the project is a private/noncommercial prototype;
- there is no current plan to sell, monetize, advertise, sponsor or otherwise commercialize the game;
- the existing attribution, license boundary and provenance warning must remain in the repository.

### Audit treatment

Future technical repository audits should classify this item as an **accepted, documented project risk**, not as an outstanding remediation task. It should not be repeated in ordinary bug lists unless one of the review triggers below becomes true.

### Review triggers

The decision must be reviewed before:

- any public binary release or redistribution outside the current prototype context;
- monetization, paid access, advertising, sponsorship or commercial licensing;
- a change to the declared asset license or source provenance;
- receipt of a copyright, trademark or takedown complaint;
- discovery of a suitable replacement asset with demonstrably better rights clearance.

This record does not assert that the upstream rights issue is resolved. It records the owner's deliberate acceptance of the known limitation for the current noncommercial prototype scope.

## Project scope and handling of externally supplied assets

Decision date: 2026-07-14

The project owner declares that the game is developed solely as a private, noncommercial prototype for personal use. There is no current plan to sell, monetize, advertise, sponsor, publish a binary release or otherwise distribute the completed game.

This declaration is a standing project constraint and should not need to be re-established during each technical import task. It does not, by itself, grant copyright permissions, change an upstream asset license or authorize the project to apply a Creative Commons license to third-party material.

### Working rule for future imports

- Technical inspection, conversion and local integration of externally supplied assets may be performed for the owner's private prototype.
- Source assets and converted outputs with no demonstrated redistribution permission must remain outside public Git history and public release artifacts.
- Public commits may contain independently authored integration code, import scripts, configuration, manifests, checksums, attribution records and installation instructions, provided they do not embed or reconstruct the restricted asset.
- A public repository is treated as public distribution of every committed file, even when the project purpose is personal and noncommercial.
- No third-party asset may be described as CC BY, CC BY-SA or otherwise relicensed by this project unless the relevant rights holder has granted that permission.
- Each third-party asset requires its own provenance record; an accepted-risk decision for one asset does not automatically cover another.

### Audit treatment

Future technical work should accept the private/noncommercial intent as established project context and should not repeatedly present it as an unresolved product requirement. Rights or provenance should be raised again only when the requested action would publish, relicense, redistribute or include the external asset in a public build or repository.

### Review triggers

This standing decision must be reviewed if any of the following occurs:

- the repository containing third-party assets is made private or public in a materially different distribution arrangement;
- a public source or binary release is planned;
- monetization, paid access, advertising, sponsorship or commercial licensing is considered;
- an asset author or rights holder supplies explicit permission or different license terms;
- a copyright, trademark or takedown complaint is received.

## Traffic Rider NPC vehicle bundle provenance

Decision date: 2026-07-15

The project owner has reviewed the provenance limitation for the Sketchfab **Traffic Rider NPC Vehicles** bundle and has decided to retain the 20 included non-heavy source models for the current private, noncommercial prototype.

The source page and embedded metadata identify Mason (`ModelzRipper`) as the uploader and state CC BY-NC 4.0. The models appear to originate from the commercial game **Traffic Rider**, while the repository contains no written authorization from the game's publisher, developer or original asset rights holders. The uploader-stated license is therefore recorded together with an incomplete upstream rights chain; it is not treated as proof that every underlying right was available for licensing.

The 20 source GLBs remain committed and are not added to `.gitignore`. They must remain unchanged until each model reaches the implementation stage defined in `docs/assets/traffic_rider_npc_vehicle_import_workflow.md`. Scania, generic articulated truck and generic rigid truck remain excluded from this approved vehicle scope.

This decision is based on the following project constraints:

- the project remains a private, noncommercial prototype for personal use;
- no public source or binary redistribution containing these assets is currently planned;
- the repository must preserve the source attribution, uploader-stated license and upstream-rights warning;
- derived geometry, Godot scenes, physics, audio and catalog data do not broaden rights in the underlying source models;
- the assets are excluded from the repository's root license;
- no contributor may describe the bundle as fully rights-cleared.

### Audit treatment

For the current private/noncommercial scope, future technical audits should treat retention of these 20 source GLBs as an **accepted, documented project risk** rather than repeatedly reopening the same provenance question. This does not assert that the upstream rights issue has been resolved.

### Review triggers

The decision must be reviewed before:

- any public source release, binary release or redistribution containing the source or derived vehicle assets;
- monetization, paid access, advertising, sponsorship or commercial licensing;
- applying a different license or removing the noncommercial restriction, attribution or provenance warning;
- a material change to the source page, displayed license or known origin of the models;
- receipt of a copyright, trademark or takedown complaint;
- discovery of replacement models with demonstrably better rights clearance.
