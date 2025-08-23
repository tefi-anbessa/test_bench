# Developer Notes & Ideas

## AI Integration

From git commit 6da446f onwards, this project has used Windsurf/Cascade AI to speed up development and improve code quality. The learnings of this process including coding conventions and project peculiarities, etc. have been captured in "Memories" on the Cascade server side.

### For Developers:
1. When initiating a new session with AI, request it to review these memories and follow the guidance therein.
2. If memories are not available, refer to the duplicated documentation in `docs/AI memories/`.
3. Always review these additional resources for guidance:
   - `DEVELOPER_NOTES.md`
   - `README.md`
   - Project documentation in `docs/`

### Maintenance:
- These guidelines and requirements will evolve over time.
- Any changes should be reflected in the documentation.
- Request the AI to update its Memories when significant changes occur.

## KISS Principle Guidelines

The project follows the KISS (Keep It Simple, Stupid) principle with these priorities:

1. **Minimal Viable Features First**:
   - Implement only requested features
   - Avoid adding unrequested functionality
   - Keep initial implementations simple and focused

2. **Testing Foundation**:
   - Ensure all tests pass before adding new features
   - Maintain test coverage for core functionality
   - Focus on stable, working features over feature completeness

3. **Incremental Development**:
   - Build a solid foundation before adding enhancements
   - Get approval for each feature before moving forward
   - Keep pull requests and changes small and focused

4. **Current Focus**:
   - Projects functionality is the current priority
   - Dashboard features should be deferred until core functionality is stable
   - Avoid premature optimization or over-engineering

5. **Code Review Guidelines**:
   - Question any added complexity
   - Challenge features that weren't explicitly requested
   - Prefer simple, maintainable solutions over clever ones

## Technical Debt
- [ ] Refactor models to incorporate i18n messages for validations
- [ ] Serve bootstrap from local dev or prod
- [ ] Write more tests for the Demand model
- [ ] Add performance optimizations for large demand calculations
- [ ] Update API documentation
- [x] Clean up old Load model references after migration

## Refactoring Opportunities
- [ ] Improve role and permissions implementation and workflow.
- [ ] Refactor projects controller with improved workflow.
- [ ] Consider extracting demand calculations into a service object
- [ ] Add type checking with Sorbet or RBS
- [ ] Implement caching for frequently accessed demand data
- [x] Upgrade to Rails 8 (Completed in rails8 branch)
- [ ] Refactor policy classes (CablePolicy, SwitchboardPolicy, MotorPolicy, LightCctPolicy, SocketCctPolicy) to use a shared concern or base class to reduce code duplication

## Potential Features
- [ ] Add more comprehensive reporting for demand calculations
- [ ] Implement bulk import/export for demands
- [ ] Add more detailed documentation for the demand calculation formulas
- [ ] See if pagy can provide usesr selectable page size
- [ ] Data revision management
- [ ] Customize devise views
- [ ] Customize devise users:
   - Allow users to self register through devise, edit their own profile and user name, email, password. 
   - Insert an admin approval in the confirmation process
   - Disable destroy, because the [future] change history will have links to users making changes. We may need to historise user name changes as well, that's a future problem. The revision management system may well include some sort of active/inactive status features. 

## Architecture Considerations
- [ ] Evaluate if we should move to a more modular architecture
- [ ] Consider API versioning strategy
- [ ] Plan for database scaling as demand data grows

## Role System Documentation

The role system is defined by the following components:

1. **Configuration**:
   - Defined in `config/constants/role.yml`
   - Uses three categories: `global_roles`, `functional_roles`, and resource-specific roles under `resources`

2. **Key Files**:
   - `app/models/role.rb`: Core role model with validation and query methods
   - `test/factories/roles.rb`: Dynamic factory that generates traits from Constants
   - `docs/ROLES_AND_PERMISSIONS.md`: Detailed documentation on the role system
   - `docs/USER_GUIDE.md`: End-user documentation for role management

3. **Integration**:
   - The Role model validates against the constants
   - Provides helper methods like `valid_roles_for` and `valid_role?`
   - Factory generates traits dynamically from the constants

## Notes
- Keep backward compatibility during the Load → Demand transition
- Document any non-obvious electrical calculation formulas
- Consider adding performance benchmarks for critical paths
