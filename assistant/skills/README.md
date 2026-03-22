# Assistant Skills

Skills are modular capabilities for the Claude Assistant. Each skill is a
folder containing a `SKILL.md` with instructions Claude follows when a user
request matches the skill's domain.

## Adding a New Skill

1. Create a folder: `skills/<skill-name>/`
2. Add `SKILL.md` with:
   - Description of what the skill does
   - When to activate (trigger conditions)
   - Step-by-step instructions for Claude
   - Required permissions (if any new ones needed in settings.json)
   - Any helper scripts referenced
3. Add required permissions to `settings.json` if the skill needs new ones
4. Update `CLAUDE.md` to list the new skill

## Skill Contract

- Skills are self-contained — all instructions in SKILL.md
- Skills can reference helper scripts in `bin/` or `lib/`
- Skills declare their required permissions
- Skills should not conflict with each other
