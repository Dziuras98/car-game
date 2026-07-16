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