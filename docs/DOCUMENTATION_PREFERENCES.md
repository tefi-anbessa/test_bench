# Documentation Preferences

## Overview
Guidelines for maintaining comprehensive documentation in the codebase for both human and AI reference.

## Protected Documentation

The following core documentation files are READ-ONLY and must not be modified by AI:
1. `docs/Documentation Preferences.md`
  - Purpose:
    - This document explains the purpose of the various other documents used to manage this software application development project.
2. `docs/DEVELOPER_NOTES.md`
  - Purposes:
    - Guidance for new developer and reminder for original developer on how the application is structured and intended to behave
    - Guidance on the implementation techniques to be followed to maintain consistency
    - Guidance for AI on how to interact with the project
    - Record the history of how things were done
    - Lists of things to do:
      - ongoing development check list (Development TODO)
      - outstanding fixes required (Technical Debt)
      - future improvements (Potential Features)
      - major restructure (Architecture Considerations)
2. `docs/TESTING.md`
  - Purposes:
    - Provide clear guidance and rules for testing the application.
3. `docs/ROLES_AND_PERMISSIONS.md`
  - Purposes:
    - Explains the roles based access control (RBAC) system
    - Details the roles and permissions for each module, as the basis for setting up tests 
    - Explains how the roles and permission system is implemented


### Protection Methods
- **AI Restriction**: 
  - These files are marked as read-only for AI assistance
  - AI will not modify these files under any circumstances
- **User Access**: 
  - Files remain fully writable by the user
  - No OS-level read-only restrictions are applied
- **Git Protection**: 
  - Marked as `-crlf -diff -merge` in Git attributes
  - Helps prevent accidental modifications
  - Can be overridden when intentional changes are needed

## Key Documentation Files

### 1. Core Documentation
- `README.md` - This document will become the default landing page in github when the app is deployed. It should conform to rails conventions for README files, including basic installation instructions, user instructions, and links to further information. It should be updated as the project matures, AI can assist.
- `docs/DEVELOPER_NOTES.md` - Development guidelines and practices (Protected)
- `docs/TESTING.md` - Testing guidelines and practices (Protected)
- `docs/ROLES_AND_PERMISSIONS.md` - Role and permission structure (Protected)
- [HOLD] `docs/MIGRATION.md` - Database migration guides

### 2. Project-Specific Documentation
- `docs/USER_GUIDE.md` - End-user documentation [TODO: Create user documentation when the project has matured enough to be deployed in production, and ready to share to other users] [HOLD: consider if it is required, or README is sufficient]
- `AI memories/` - AI-specific context and knowledge

## Best Practices

### 1. Documentation Structure
- Keep documentation in the project root or `docs/` directory
- Use clear, descriptive filenames
- Organize related documents in subdirectories when needed

### 2. Formatting
- Use Markdown for all documentation
- Include a table of contents for longer documents
- Use consistent heading levels
- Add code blocks with syntax highlighting

### 3. Content Guidelines
- Document both what and why, not just how
- Keep documentation up-to-date with code changes
- Include examples where helpful
- Document edge cases and gotchas

### 4. AI Considerations
- Document project-specific patterns and conventions
- Include context that might not be obvious from code
- Keep documentation in version control
- Use clear, unambiguous language
