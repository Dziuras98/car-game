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

The project owner has reviewed the provenance limitation of the **Traffic Rider NPC Vehicles** bundle and explicitly accepts retention of the 20 individually extracted non-heavy vehicle GLBs in this repository.

The decision is based on the following project constraints and owner instructions:

- the game is a personal, private-purpose and noncommercial prototype;
- the owner intends to use the models only inside this project;
- the uploader-stated embedded license is CC BY-NC 4.0;
- the bundle identifies Mason (`ModelzRipper`) as uploader;
- the model title and contents indicate origin in the commercial game *Traffic Rider*;
- the repository does not contain evidence that the uploader owns the upstream game assets or was authorized by the relevant upstream rights holder to license them;
- the owner understands that noncommercial use and uploader-stated metadata do not resolve an incomplete upstream rights chain;
- the owner nevertheless directs the project to retain and technically integrate the 20 committed source GLBs;
- the Scania, generic articulated truck and generic rigid truck remain excluded.

### Accepted repository treatment

- The 20 source GLBs remain committed and are not added to `.gitignore`.
- Their derived GLBs may also be committed when required for wheel separation, pivot correction or canonical Godot orientation.
- Source files must remain unchanged; derived technical adaptations must use separate paths.
- Source and derived files remain excluded from the repository's root `LICENSE`.
- `THIRD_PARTY_NOTICES.md` must preserve attribution, the uploader-stated license and the unresolved provenance warning.
- The import workflow in `docs/assets/traffic_rider_npc_vehicle_import_workflow.md` governs every model.

### Audit treatment

Ordinary technical audits should classify the known Traffic Rider provenance limitation as an **accepted, documented project risk**, not as a recurring remediation item. Audits should still report missing attribution, accidental relicensing, inclusion of an excluded large truck, destructive replacement of a source GLB or use outside the accepted scope.

### Review triggers

This decision must be reviewed before:

- any public binary release or redistribution beyond the current source repository and private prototype use;
- monetization, paid access, advertising, sponsorship or commercial licensing;
- changing or removing the uploader attribution, noncommercial restriction or provenance warning;
- adding one of the three excluded large-truck models;
- a material change to the source page or uploader-stated license;
- receipt of permission from an upstream rights holder or discovery of a demonstrably cleared replacement;
- receipt of a copyright, trademark or takedown complaint.

This record does not assert ownership, upstream authorization or full rights clearance. It records the owner's deliberate acceptance of the identified risk for the stated project scope.
