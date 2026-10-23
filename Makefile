# Agent setup targets from coding-agent-setup. Add project targets below.
# `ci` is the full check agents run before completing a package
# (docs/agents/WORKFLOW.md, "Testing"); replace the placeholder per project.

SKILLS ?=

.PHONY: ci skills-update

ci:
	@echo "PROJECT: replace the ci target with the real check (format, lint, tests)" >&2
	@exit 1

# Updates repo skills (all, or SKILLS="name ..."); see docs/agents/WORKFLOW.md.
skills-update:
	./scripts/skills-update.sh $(SKILLS)
