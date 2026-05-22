# hackify — GitHub Copilot CLI package

GitHub Copilot CLI has NO plugin / skill / custom-instruction model as of
hackify v0.2.0. You cannot register hackify as a reusable workflow; the
only integration path is to paste the SKILL.md body into a Copilot CLI
prompt manually each time you start a task.

## Disclaimer

This runtime is supported on a best-effort basis. If GitHub ships a plugin
or persistent-instructions model in the future, hackify will add proper
integration; until then, treat this MANIFEST.md as the only deliverable for
copilot-cli and copy the body below into your Copilot CLI session as
needed.

## How to use

1. Open a Copilot CLI session in your project.
2. Paste everything between the `===== BEGIN SKILL.md =====` and
   `===== END SKILL.md =====` markers below as your initial prompt.
3. Follow the workflow steps the SKILL.md prescribes (clarification gate,
   plan gate, implementation, verification, review).
4. For the companion skills (`quick`, `groom`, etc.) repeat the same
   paste-on-demand pattern with their SKILL.md bodies from the canonical
   `skills/<name>/SKILL.md`.

===== BEGIN SKILL.md =====
