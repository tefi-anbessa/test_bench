# KISS Principle in Development

## Core Principle
**K**eep **I**t **S**imple, **S**tupid (KISS) is the guiding philosophy for all development work.

## Development Priorities

### 1. Minimal Viable Features (MVF) First
- Implement only explicitly requested features
- Avoid scope creep and "nice-to-have" additions
- Keep initial implementations simple and focused
- Get user approval before expanding functionality

### 2. Testing Foundation
- All tests must pass before adding new features
- Maintain comprehensive test coverage for core functionality
- Prioritize stable, working features over feature completeness
- Write tests that verify behavior, not implementation

### 3. Incremental Development
- Build a solid foundation before adding enhancements
- Get approval for each feature before proceeding
- Keep pull requests small and focused (200-300 lines max)
- Break large features into smaller, mergeable chunks

### 4. Current Focus Areas
1. **Core Functionality**
   - Projects functionality is the top priority
   - Ensure all basic CRUD operations work flawlessly
   - Validate business rules and validations

2. **Deferred Items**
   - Dashboard features (defer until core is stable)
   - Performance optimizations (premature optimization is avoided)
   - UI/UX enhancements (unless critical for functionality)

### 5. Code Review Guidelines
- **Question Complexity**: Challenge any added complexity
- **Feature Validation**: Verify all features were explicitly requested
- **Simplicity First**: Prefer simple, maintainable solutions
- **Documentation**: Ensure clear, concise code comments
- **Technical Debt**: Document any shortcuts taken for future reference

### 6. Implementation Guidelines
- Follow Rails conventions ("Convention over Configuration")
- Use standard libraries over custom solutions
- Prefer clarity over cleverness
- Document any non-obvious decisions
- Keep methods small and focused (single responsibility)

### 7. When in Doubt
1. Ask for clarification
2. Propose the simplest solution
3. Get feedback before proceeding
4. Document the decision-making process
